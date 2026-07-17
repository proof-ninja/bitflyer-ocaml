open Lwt
open Common

let host = "api.bitflyer.com"

(* API制限: 同じIPアドレスからは5分間で500回まで。
   see: https://lightning.bitflyer.com/docs -> API制限 *)
let global_limiter = RateLimiter.create ~capacity:500 ~window:300.0

(* 下記のPrivate APIは合計で5分間で300回まで:
   新規注文を出す, 新規の親注文を出す（特殊注文）, すべての注文をキャンセルする *)
let order_limiter = RateLimiter.create ~capacity:300 ~window:300.0

let order_paths = [
    "/v1/me/sendchildorder";
    "/v1/me/sendparentorder";
    "/v1/me/cancelallchildorders";
  ]

(* 成功時に本文が空（例: キャンセル系APIの200 OK）の場合があるため、
   空文字列は `Null として扱う。 *)
let json_of_body body =
  match String.trim body with
  | "" -> `Null
  | body -> Json.from_string body

let get_public pathname query =
  let uri =
    Uri.make ~scheme:"https" ~host ~path:pathname ()
    |> fun uri -> Uri.with_query' uri query
  in
  RateLimiter.acquire global_limiter >>= fun () ->
  Http.get uri |> Lwt.map json_of_body

let get auth pathname query =
  let uri =
    Uri.make ~scheme:"https" ~host ~path:pathname ()
    |> fun uri -> Uri.with_query' uri query
  in
  let path = Uri.path_and_query uri in
  let headers = Auth.make_header auth "GET" path "" in
  RateLimiter.acquire global_limiter >>= fun () ->
  Http.get ~headers uri >>= fun body ->
  json_of_body body
  |> Lwt.return

let post auth path data =
  let uri = Uri.make ~scheme:"https" ~host ~path () in
  let headers = Auth.make_header auth "POST" path data in
  RateLimiter.acquire global_limiter >>= fun () ->
  (if List.mem path order_paths then RateLimiter.acquire order_limiter else Lwt.return ()) >>= fun () ->
  Http.post ~headers uri data >>= fun body ->
  json_of_body body
  |> Lwt.return
