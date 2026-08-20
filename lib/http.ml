open Lwt
open Cohttp_lwt_unix
open Common

let curlcmd meth headers uri body =
  let headers =
    List.map (fun (k, v) -> !%"-H '%s: %s'" k v) headers |> String.concat " "
  in
  !%"curl -X %s %s --data '%s' '%s'" meth headers body (Uri.to_string uri)

exception HttpException of string * Uri.t * exn

(* HTTPレベルではエラーなくても、ステータスコードが2xx以外(bitFlyerはAPIエラーを
   400/401/403等の非2xxで返す)の場合はbitFlyerが注文/リクエストを拒否している。
   以前はここでステータスコードを一切見ずに本文をそのままJSONとして返していたため、
   拒否されたsendchildorderが呼び出し側(Order_execution.place_bitflyer_market_order)
   から「成功」に見えてしまい、既存の照合・再送ロジックが一度も発動しないまま
   実際には発注されていない注文を「約定済み」として扱う不具合を引き起こしていた
   (2026-08-20の巻き戻し騒動の調査で発見)。 *)
exception ApiError of string * Uri.t * Cohttp.Code.status_code * string

let () =
  Printexc.register_printer (function
    | ApiError (meth, uri, status, body) ->
        Some
          (!%"Bitflyer.Http.ApiError(%s, %s, %s, %s)" meth (Uri.to_string uri)
             (Cohttp.Code.string_of_status status)
             body)
    | _ -> None)

let handle_response meth uri (resp, body) =
  let status = Cohttp.Response.status resp in
  Cohttp_lwt.Body.to_string body >>= fun body_str ->
  if Cohttp.Code.is_success (Cohttp.Code.code_of_status status) then
    Lwt.return body_str
  else Lwt.fail (ApiError (meth, uri, status, body_str))

let get ?log ?(headers = []) uri =
  Option.iter
    (fun show -> show (!%"Http.get $ %s" (curlcmd "GET" headers uri "")))
    log;
  try%lwt
    let headers = Cohttp.Header.of_list headers in
    Client.get ~headers uri >>= handle_response "GET" uri
  with
  | ApiError _ as exn -> raise exn
  | exn -> raise (HttpException ("GET", uri, exn))

let post ?log ?(headers = []) uri data =
  Option.iter
    (fun show -> show (!%"Http.post $ %s" (curlcmd "POST" headers uri data)))
    log;
  try%lwt
    let headers = Cohttp.Header.of_list headers in
    let body = Cohttp_lwt.Body.of_string data in
    Client.post ~headers uri ~body >>= handle_response "POST" uri
  with
  | ApiError _ as exn -> raise exn
  | exn -> raise (HttpException ("POST", uri, exn))
