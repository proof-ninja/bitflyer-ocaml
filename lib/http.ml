open Lwt
open Cohttp_lwt_unix
open Common

let curlcmd meth headers uri body =
  let headers =
    List.map (fun (k, v) -> !%"-H '%s: %s'" k v) headers |> String.concat " "
  in
  !%"curl -X %s %s --data '%s' '%s'" meth headers body (Uri.to_string uri)

exception HttpException of string * Uri.t * exn

let get ?log ?(headers=[]) uri =
  Option.iter
    (fun show -> show (!%"Http.get $ %s" (curlcmd "GET" headers uri ""))) log;
  try%lwt
    let headers = Cohttp.Header.of_list headers in
    Client.get ~headers uri >>= fun (_resp, body) ->
    Cohttp_lwt.Body.to_string body
  with
  | exn -> raise (HttpException ("GET", uri, exn))


let post ?log ?(headers=[]) uri data =
  Option.iter
    (fun show ->
      show (!%"Http.post $ %s" (curlcmd "POST" headers uri data))) log;
  try%lwt
     let headers = Cohttp.Header.of_list headers in
     let body = Cohttp_lwt.Body.of_string data in
     Client.post ~headers uri ~body >>= fun (_resp, body) ->
     Cohttp_lwt.Body.to_string body
  with
  | exn -> raise (HttpException ("POST", uri, exn))
