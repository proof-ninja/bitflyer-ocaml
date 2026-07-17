open Bitflyer
module Json = Bitflyer__Common.Json
open Lwt

let auth = Auth.auth ()

(* サンプル: FX_BTC_JPY (信用取引) の best_bid を監視し、閾値以上になるたびに
   成行の信用買い注文を出す。条件を満たしている間は毎回発注するので、
   実際に動かす際は size や threshold の設定に注意すること。 *)
let watch_and_buy auth ~product_code ~threshold ~size =
  Realtime.updates product_code >>= fun stream ->
  Lwt_stream.iter_s
    (function
      | Realtime.Ticker ticker when ticker.PublicApi.best_bid >= threshold ->
         Log.info "best_bid %f >= %f: sending market buy order"
           ticker.PublicApi.best_bid threshold;
         PrivateApi.sendchildorder auth product_code Market Buy size >>= fun json ->
         Log.debug "order response: %s" (Json.to_string json);
         Lwt.return ()
      | Realtime.Ticker _ | Realtime.Board _ -> Lwt.return ())
    stream

(* 実行する場合は下記のように呼び出す:
   Lwt_main.run (watch_and_buy auth ~product_code:"FX_BTC_JPY" ~threshold:5_000_000.0 ~size:0.01) *)

let () =
  Log.set_log_level Log.DEBUG;
(*  buy auth "BTC_JPY" 0.001;*)
(*  let latest = get_executions auth "BTC_JPY" |> List.hd in
  ignore latest*)
  try
    Lwt_main.run begin
        PublicApi.getboard "BTC_JPY" >>= fun board ->
        print_endline (Json.show (PublicApi.board_to_yojson board));
        return ()
end
  with
  | e -> prerr_endline (Printexc.to_string e)
