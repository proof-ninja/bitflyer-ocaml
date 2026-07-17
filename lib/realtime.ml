open Lwt
open Common

(* bitFlyer Realtime API: JSON-RPC 2.0 over WebSocket
   wss://ws.lightstream.bitflyer.com/json-rpc
   channel = "lightning_ticker_<product_code>" | "lightning_board_snapshot_<product_code>"
           | "lightning_board_<product_code>" | "lightning_executions_<product_code>" *)

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
  client_of_uri uri >>= fun client ->
  Websocket_lwt_unix.connect client uri

let next_id =
  let counter = ref 0 in
  fun () -> incr counter; !counter

let send_subscribe conn channel =
  let request = `Assoc [
      ("jsonrpc", `String "2.0");
      ("method", `String "subscribe");
      ("params", `Assoc [("channel", `String channel)]);
      ("id", `Int (next_id ()));
    ]
  in
  Websocket_lwt_unix.write conn
    (Websocket.Frame.create ~content:(Json.to_string request) ())

(* 板の現在状態。bids は価格の高い順、asks は安い順に並ぶ。
   購読で届く lightning_board_snapshot/lightning_board のメッセージは
   HTTP の板情報 (GET /v1/getboard) と同じ形なので [PublicApi.board] を再利用する。 *)
type orderbook = {
    mid_price: float;
    bids: (float * float) list; (* (price, size) *)
    asks: (float * float) list; (* (price, size) *)
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
       let current = List.filter (fun (price, _) -> price <> level.price) current in
       if level.size = 0.0 then current else (level.price, level.size) :: current)
    current levels
  |> List.sort (fun (p1, _) (p2, _) -> compare p1 p2)

let apply_board_message (message : PublicApi.board) (orderbook : orderbook) =
  {
    mid_price = message.mid_price;
    bids = apply_levels ~compare:(fun p1 p2 -> Stdlib.compare p2 p1) message.bids orderbook.bids;
    asks = apply_levels ~compare:Stdlib.compare message.asks orderbook.asks;
  }

type update =
  | Ticker of PublicApi.ticker
  | Board of orderbook

let channel_message_of_frame (frame : Websocket.Frame.t) =
  match frame.opcode with
  | Websocket.Frame.Opcode.Text ->
     let json = Json.from_string frame.content in
     (match Json.Util.member "method" json with
      | `String "channelMessage" ->
         let params = Json.Util.member "params" json in
         let channel = Json.Util.member "channel" params |> Json.Util.to_string in
         let message = Json.Util.member "message" params in
         Some (channel, message)
      | _ -> None)
  | _ -> None

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
    Websocket_lwt_unix.read conn >>= fun frame ->
    match frame.Websocket.Frame.opcode with
    | Websocket.Frame.Opcode.Ping ->
       Websocket_lwt_unix.write conn
         (Websocket.Frame.create ~opcode:Websocket.Frame.Opcode.Pong ())
       >>= next
    | Websocket.Frame.Opcode.Close -> Lwt.return_none
    | _ ->
       (match channel_message_of_frame frame with
        | Some (channel, message) when channel = ticker_channel ->
           Lwt.return_some (Ticker (PublicApi.ticker_of_json message))
        | Some (channel, message) when channel = board_snapshot_channel ->
           orderbook := apply_board_message (PublicApi.board_of_json message) empty_orderbook;
           Lwt.return_some (Board !orderbook)
        | Some (channel, message) when channel = board_channel ->
           orderbook := apply_board_message (PublicApi.board_of_json message) !orderbook;
           Lwt.return_some (Board !orderbook)
        | Some _ | None -> next ())
  in
  Lwt.return (Lwt_stream.from next)
