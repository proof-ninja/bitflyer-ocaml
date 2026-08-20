open Lwt
open Common

let host = "api.bitflyer.com"

(* API制限: 同じIPアドレスからは5分間で500回まで。
   see: https://lightning.bitflyer.com/docs -> API制限 *)
let global_limiter = RateLimiter.create ~capacity:500 ~window:300.0

(* 下記のPrivate APIは合計で5分間で300回まで:
   新規注文を出す, 新規の親注文を出す（特殊注文）, すべての注文をキャンセルする *)
let order_limiter = RateLimiter.create ~capacity:300 ~window:300.0

let order_paths =
  [
    "/v1/me/sendchildorder";
    "/v1/me/sendparentorder";
    "/v1/me/cancelallchildorders";
  ]

(* 成功時に本文が空（例: キャンセル系APIの200 OK）の場合があるため、
   空文字列は `Null として扱う。 *)
let json_of_body body =
  match String.trim body with "" -> `Null | body -> Json.from_string body

(* bitFlyerのAPIエラーは本文が {"status": <負の整数>, "error_message": "...",
   "data": null} という共通形式で返る(例: {"status":-208,"error_message":
   "Order is not accepted. Please try again later.","data":null})。
   [status]はbitFlyer独自のエラーコードで、呼び出し元がエラーの種類
   (一時的な混雑なのか、恒久的な拒否なのか)を判別するのに使う。 *)
exception Api_error of int * string

let () =
  Printexc.register_printer (function
    | Api_error (status, error_message) ->
        Some (!%"Bitflyer.ApiCommon.Api_error(status=%d, %s)" status error_message)
    | _ -> None)

let api_error_of_body body_str =
  try
    let open Json.Util in
    let json = Json.from_string body_str in
    let status = member "status" json |> to_int in
    let error_message = member "error_message" json |> to_string in
    Some (Api_error (status, error_message))
  with _ -> None

(* Http.get/postはHTTPステータスが2xx以外のときHttp.ApiErrorを投げる。本文が
   上記のbitFlyerエラー形式でパースできればより詳細なApi_errorに載せ替え、
   パースできなければ(想定外の形式の応答など)元の例外をそのまま伝播させる。 *)
let reraise_as_api_error f =
  Lwt.catch f (function
    | Http.ApiError (_, _, _, body) as exn -> (
        match api_error_of_body body with
        | Some e -> Lwt.fail e
        | None -> Lwt.fail exn)
    | exn -> Lwt.fail exn)

let get_public pathname query =
  let uri =
    Uri.make ~scheme:"https" ~host ~path:pathname () |> fun uri ->
    Uri.with_query' uri query
  in
  RateLimiter.acquire global_limiter >>= fun () ->
  Http.get uri |> Lwt.map json_of_body

let get auth pathname query =
  let uri =
    Uri.make ~scheme:"https" ~host ~path:pathname () |> fun uri ->
    Uri.with_query' uri query
  in
  let path = Uri.path_and_query uri in
  let headers = Auth.make_header auth "GET" path "" in
  RateLimiter.acquire global_limiter >>= fun () ->
  reraise_as_api_error (fun () -> Http.get ~headers uri)
  >>= fun body -> json_of_body body |> Lwt.return

let post auth path data =
  let uri = Uri.make ~scheme:"https" ~host ~path () in
  let headers = Auth.make_header auth "POST" path data in
  RateLimiter.acquire global_limiter >>= fun () ->
  (if List.mem path order_paths then RateLimiter.acquire order_limiter
   else Lwt.return ())
  >>= fun () ->
  reraise_as_api_error (fun () -> Http.post ~headers uri data)
  >>= fun body -> json_of_body body |> Lwt.return
