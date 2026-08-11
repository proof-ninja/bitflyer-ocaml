open Lwt
open Common

(* bitFlyer Realtime API: JSON-RPC 2.0 over WebSocket
   wss://ws.lightstream.bitflyer.com/json-rpc
   channel = "lightning_ticker_<product_code>" | "lightning_board_snapshot_<product_code>"
           | "lightning_board_<product_code>" | "lightning_executions_<product_code>"
           | "child_order_events" (認証必要) | "parent_order_events" (認証必要) *)

let endpoint = "wss://ws.lightstream.bitflyer.com/json-rpc"

(* Resolver_lwt の標準サービス解決 (/etc/services) は "wss" を認識しないため、
   TLS クライアントを直接組み立てる。 *)
let client_of_uri uri =
  let host = Uri.host_with_default ~default:"" uri in
  let port = match Uri.port uri with Some p -> p | None -> 443 in
  Lwt_unix.gethostbyname host >>= fun entry ->
  let ip = Ipaddr_unix.of_inet_addr entry.h_addr_list.(0) in
  Lwt.return (`TLS (`Hostname host, `IP ip, `Port port))

let connect () =
  let uri = Uri.of_string endpoint in
  client_of_uri uri >>= fun client -> Websocket_lwt_unix.connect client uri

let next_id =
  let counter = ref 0 in
  fun () ->
    incr counter;
    !counter

let send_subscribe conn channel =
  let request =
    `Assoc
      [
        ("jsonrpc", `String "2.0");
        ("method", `String "subscribe");
        ("params", `Assoc [ ("channel", `String channel) ]);
        ("id", `Int (next_id ()));
      ]
  in
  Websocket_lwt_unix.write conn
    (Websocket.Frame.create ~content:(Json.to_string request) ())

(* 板の現在状態。bids は価格の高い順、asks は安い順に並ぶ。
   購読で届く lightning_board_snapshot/lightning_board のメッセージは
   HTTP の板情報 (GET /v1/getboard) と同じ形なので [PublicApi.board] を再利用する。 *)
type orderbook = {
  mid_price : float;
  bids : (float * float) list; (* (price, size) *)
  asks : (float * float) list; (* (price, size) *)
}

let empty_orderbook = { mid_price = 0.0; bids = []; asks = [] }

let best_bid orderbook =
  match orderbook.bids with (price, _) :: _ -> Some price | [] -> None

let best_ask orderbook =
  match orderbook.asks with (price, _) :: _ -> Some price | [] -> None

(* level.size = 0 はその価格帯の削除を意味する（差分更新の反映）。 *)
let apply_levels ~compare (levels : PublicApi.level list) current =
  List.fold_left
    (fun current (level : PublicApi.level) ->
      let current =
        List.filter (fun (price, _) -> price <> level.price) current
      in
      if level.size = 0.0 then current else (level.price, level.size) :: current)
    current levels
  |> List.sort (fun (p1, _) (p2, _) -> compare p1 p2)

let apply_board_message (message : PublicApi.board) (orderbook : orderbook) =
  {
    mid_price = message.mid_price;
    bids =
      apply_levels
        ~compare:(fun p1 p2 -> Stdlib.compare p2 p1)
        message.bids orderbook.bids;
    asks = apply_levels ~compare:Stdlib.compare message.asks orderbook.asks;
  }

type update = Ticker of PublicApi.ticker | Board of orderbook

let channel_message_of_frame (frame : Websocket.Frame.t) =
  match frame.opcode with
  | Websocket.Frame.Opcode.Text -> (
      let json = Json.from_string frame.content in
      match Json.Util.member "method" json with
      | `String "channelMessage" ->
          let params = Json.Util.member "params" json in
          let channel =
            Json.Util.member "channel" params |> Json.Util.to_string
          in
          let message = Json.Util.member "message" params in
          Some (channel, message)
      | _ -> None)
  | _ -> None

(* ネットワーク経路が明示的なCloseもRST/FINも送らずに黙って死んだ場合
   (Wi-Fiのスリープ復帰やNATのセッションタイムアウトなど)、[Websocket_lwt_unix.read]
   は例外にならずただ無期限にpendingし続け、呼び出し側の再接続ロジックが一切働かなく
   なる。市況が動いていれば通常はもっと頻繁にtickerが届くはずなので、それより
   十分長い時間何も届かなければ接続が死んでいるとみなして例外を投げる。 *)
let read_timeout = 90.0

type read_result = Received of Websocket.Frame.t | Timed_out

let read_with_timeout conn =
  Lwt.pick
    [
      (Websocket_lwt_unix.read conn >|= fun frame -> Received frame);
      (Lwt_unix.sleep read_timeout >|= fun () -> Timed_out);
    ]

(* [channel]から届くchannelMessageだけを[of_json]でデコードして流すストリーム。
   Ping/Close/タイムアウトの扱いは[updates]と共通(複数チャンネルを1本のupdateに
   合流させる[updates]自体はこの共通化の対象外にしている)。 *)
let channel_stream conn channel of_json =
  let rec next () =
    read_with_timeout conn >>= function
    | Timed_out ->
        Lwt.fail_with
          (!%"Realtime: no data received within %.0fs, treating connection as \
              dead"
             read_timeout)
    | Received frame -> (
        match frame.Websocket.Frame.opcode with
        | Websocket.Frame.Opcode.Ping ->
            Websocket_lwt_unix.write conn
              (Websocket.Frame.create ~opcode:Websocket.Frame.Opcode.Pong ())
            >>= next
        | Websocket.Frame.Opcode.Close ->
            Lwt.fail_with "Realtime: server closed the connection"
        | _ -> (
            match channel_message_of_frame frame with
            | Some (c, message) when c = channel ->
                Lwt.return_some (of_json message)
            | Some _ | None -> next ()))
  in
  Lwt_stream.from next

(* [updates product_code] は WebSocket に接続し、Ticker と 板情報(Board) の
   両チャンネルを購読して、受信するたびに最新状態を [update Lwt_stream.t] として流す。
   Board は差分を内部で積算した「その時点での板の状態」を返す。 *)
let updates product_code =
  connect () >>= fun conn ->
  let ticker_channel = !%"lightning_ticker_%s" product_code in
  let board_snapshot_channel = !%"lightning_board_snapshot_%s" product_code in
  let board_channel = !%"lightning_board_%s" product_code in
  send_subscribe conn ticker_channel >>= fun () ->
  send_subscribe conn board_snapshot_channel >>= fun () ->
  send_subscribe conn board_channel >>= fun () ->
  let orderbook = ref empty_orderbook in
  let rec next () =
    read_with_timeout conn >>= function
    | Timed_out ->
        Lwt.fail_with
          (!%"Realtime: no data received within %.0fs, treating connection as \
              dead"
             read_timeout)
    | Received frame -> (
        match frame.Websocket.Frame.opcode with
        | Websocket.Frame.Opcode.Ping ->
            Websocket_lwt_unix.write conn
              (Websocket.Frame.create ~opcode:Websocket.Frame.Opcode.Pong ())
            >>= next
        | Websocket.Frame.Opcode.Close ->
            Lwt.fail_with "Realtime: server closed the connection"
        | _ -> (
            match channel_message_of_frame frame with
            | Some (channel, message) when channel = ticker_channel ->
                Lwt.return_some (Ticker (PublicApi.ticker_of_json message))
            | Some (channel, message) when channel = board_snapshot_channel ->
                orderbook :=
                  apply_board_message
                    (PublicApi.board_of_json message)
                    empty_orderbook;
                Lwt.return_some (Board !orderbook)
            | Some (channel, message) when channel = board_channel ->
                orderbook :=
                  apply_board_message
                    (PublicApi.board_of_json message)
                    !orderbook;
                Lwt.return_some (Board !orderbook)
            | Some _ | None -> next ()))
  in
  Lwt.return (Lwt_stream.from next)

(* 約定 (lightning_executions_<product_code>)。公開チャンネルなので認証不要。
   1メッセージにつき複数件の約定がまとめて配信される。sideは板寄せ(itayose)で
   約定した場合に空文字列になることがある(公式ドキュメント記載)ため、
   Common.sideではなくstringのまま持つ。 *)
type execution = {
  id : int;
  side : string; (* "BUY" | "SELL" | "" (板寄せ時) *)
  price : float;
  size : float;
  exec_date : string;
  buy_child_order_acceptance_id : string;
  sell_child_order_acceptance_id : string;
}
[@@deriving yojson]

let execution_of_json json =
  match execution_of_yojson json with
  | Ok execution -> execution
  | Error msg -> failwith (!%"Realtime.execution_of_json: %s" msg)

let executions_of_json json =
  Json.Util.to_list json |> List.map execution_of_json

let execution_updates product_code =
  connect () >>= fun conn ->
  let channel = !%"lightning_executions_%s" product_code in
  send_subscribe conn channel >>= fun () ->
  Lwt.return (channel_stream conn channel executions_of_json)

(* Realtime APIの認証(child_order_events/parent_order_eventsの購読に必要)。
   authリクエスト送信後、公式ドキュメントの指示通り「認証完了またはエラーの
   レスポンスを確認してから次の動作を実行する」ため、[id]が一致する応答
   ({"result": true}) が届くまで待つ。channelMessage(購読中の他チャンネルの通知)は
   ここでは無視して読み飛ばす(まだどのチャンネルも購読していないので通常は
   届かないはずだが、念のため)。 *)
let auth_timeout = 10.0

let send_auth conn (auth : Auth.t) =
  let nonce = String.init 32 (fun _ -> "0123456789abcdef".[Random.int 16]) in
  let timestamp = Datetime.to_millisec (Datetime.now ()) in
  let signature = Auth.sign_realtime auth ~timestamp ~nonce in
  let request_id = next_id () in
  let request =
    `Assoc
      [
        ("jsonrpc", `String "2.0");
        ("method", `String "auth");
        ( "params",
          `Assoc
            [
              ("api_key", `String (Auth.api_key auth));
              ("timestamp", `Int timestamp);
              ("nonce", `String nonce);
              ("signature", `String signature);
            ] );
        ("id", `Int request_id);
      ]
  in
  Websocket_lwt_unix.write conn
    (Websocket.Frame.create ~content:(Json.to_string request) ())
  >>= fun () ->
  let rec wait_for_result () =
    Lwt.pick
      [
        (Websocket_lwt_unix.read conn >|= fun frame -> Some frame);
        (Lwt_unix.sleep auth_timeout >|= fun () -> None);
      ]
    >>= function
    | None -> Lwt.fail_with "Realtime: auth timed out"
    | Some frame -> (
        match frame.Websocket.Frame.opcode with
        | Websocket.Frame.Opcode.Text -> (
            let json = Json.from_string frame.content in
            match Json.Util.member "id" json with
            | `Int id when id = request_id -> (
                match Json.Util.member "result" json with
                | `Bool true -> Lwt.return_unit
                | _ ->
                    Lwt.fail_with (!%"Realtime: auth failed: %s" frame.content))
            | _ -> wait_for_result ())
        | _ -> wait_for_result ())
  in
  wait_for_result ()

(* 注文イベント (child_order_events)。認証必要。product_codeによる絞り込みは無く
   全アカウント共通。event_typeによって存在するフィールドが異なる
   ("ORDER" | "ORDER_FAILED" | "CANCEL" | "CANCEL_FAILED" | "EXECUTION" | "EXPIRE")
   ため、product_code/event_date/event_type以外は全てoptionにしている。 *)
type child_order_event = {
  product_code : string;
  event_date : string;
  event_type : string;
  child_order_id : string option;
  child_order_acceptance_id : string option;
  child_order_type : string option;
  side : string option;
  price : float option;
  size : float option;
  expire_date : string option; (* ORDER, EXECUTIONで使用 *)
  reason : string option; (* ORDER_FAILEDで使用 *)
  exec_id : int option; (* EXECUTIONで使用 *)
  commission : float option; (* EXECUTIONで使用 *)
  sfd : float option; (* EXECUTIONで使用 *)
  outstanding_size : float option; (* EXECUTIONで使用 *)
}
[@@deriving yojson]

let child_order_event_of_json json =
  match child_order_event_of_yojson json with
  | Ok event -> event
  | Error msg -> failwith (!%"Realtime.child_order_event_of_json: %s" msg)

let child_order_events auth =
  connect () >>= fun conn ->
  send_auth conn auth >>= fun () ->
  let channel = "child_order_events" in
  send_subscribe conn channel >>= fun () ->
  Lwt.return (channel_stream conn channel child_order_event_of_json)

(* 親注文（特殊注文）イベント (parent_order_events)。認証必要。
   product_codeによる絞り込みは無く全アカウント共通。child_order_eventsと同様、
   event_typeによって存在するフィールドが異なる
   ("ORDER" | "ORDER_FAILED" | "CANCEL" | "TRIGGER" | "COMPLETE" | "EXPIRE")
   ため、product_code/event_date/event_type以外は全てoptionにしている。 *)
type parent_order_event = {
  product_code : string;
  event_date : string;
  event_type : string;
  parent_order_id : string option;
  parent_order_acceptance_id : string option;
  parent_order_type : string option;
  reason : string option;
  child_order_type : string option;
  parameter_index : int option;
  child_order_acceptance_id : string option;
  side : string option;
  price : float option;
  size : float option;
  expire_date : string option;
}
[@@deriving yojson]

let parent_order_event_of_json json =
  match parent_order_event_of_yojson json with
  | Ok event -> event
  | Error msg -> failwith (!%"Realtime.parent_order_event_of_json: %s" msg)

let parent_order_events auth =
  connect () >>= fun conn ->
  send_auth conn auth >>= fun () ->
  let channel = "parent_order_events" in
  send_subscribe conn channel >>= fun () ->
  Lwt.return (channel_stream conn channel parent_order_event_of_json)
