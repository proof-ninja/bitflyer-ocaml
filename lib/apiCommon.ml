open Lwt
open Common

let host = "api.bitflyer.com"

let get_public pathname query =
  let uri =
    Uri.make ~scheme:"https" ~host ~path:pathname ()
    |> fun uri -> Uri.with_query' uri query
  in
  Unix.sleep 1;
  Http.get uri |> Lwt.map Json.from_string

let get auth pathname query =
  let uri =
    Uri.make ~scheme:"https" ~host ~path:pathname ()
    |> fun uri -> Uri.with_query' uri query
  in
  let path = Uri.path_and_query uri in
  let headers = Auth.make_header auth "GET" path "" in
  Unix.sleep 1;
  Http.get ~headers uri >>= fun body ->
  Json.from_string body
  |> Lwt.return

let post auth path data =
  let uri = Uri.make ~scheme:"https" ~host ~path () in
  let headers = Auth.make_header auth "POST" path data in
  Http.post ~headers uri data >>= fun body ->
  Json.from_string body
  |> Lwt.return
