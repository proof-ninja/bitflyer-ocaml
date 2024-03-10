open Lwt
open Cohttp_lwt_unix

let get ?(headers=[]) host path query =
  let uri =
    Uri.make ~scheme:"https" ~host ~path ()
    |> fun uri -> Uri.with_query' uri query
  in
  let headers = Cohttp.Header.of_list headers in
  Client.get ~headers uri >>= fun (_resp, body) ->
  Cohttp_lwt.Body.to_string body

let post ?(headers=[]) host path data =
  let uri =
    Uri.make ~scheme:"https" ~host ~path ()
  in
  let headers = Cohttp.Header.of_list headers in
  let body = Cohttp_lwt.Body.of_string data in
  Client.post ~headers uri ~body >>= fun (_resp, body) ->
  Cohttp_lwt.Body.to_string body


(*open Lwt.Infix
open H2
module Client = H2_lwt_unix.Client

let (!%) s = Printf.sprintf s

let response_handler notify_response_received response response_body =
  (* `response` contains information about the response that we received. We're
   * looking at the status to know whether our request produced a successful
   * response, but we could also get the response headers, for example. *)
  match response.Response.status with
  | `OK ->
    (* If we got a successful response, we're going to read the response body
     * as it arrives, and print its fragments as we receive them. *)
    let rec read_response () =
      Body.Reader.schedule_read
        response_body
        ~on_read:(fun bigstring ~off ~len ->
          (* Once a response body chunk is handed to us (as a bigarray, and an
           * offset and length into that bigarray), we'll copy it into a string
           * and print it to stdout. *)
          let response_fragment = Bytes.create len in
          Bigstringaf.blit_to_bytes
            bigstring
            ~src_off:off
            response_fragment
            ~dst_off:0
            ~len;
          print_string (Bytes.to_string response_fragment);
          (* We need to make sure that we register another read of the response
           * body after we're done handling a fragment, as it will not be
           * registered for us. This is where our recursive function comes in
           * handy. *)
          read_response ())
        ~on_eof:(fun () ->
          (* Signal to the caller of the HTTP/2 request that we are now done
           * handling the response, and the program can continue. *)
          Lwt.wakeup_later notify_response_received ())
    in
    read_response ()
  | _ ->
    (* We didn't get a successful status in the response. Just print what we
     * received to stderr and bail early. *)
    Format.eprintf "Unsuccessful response: %a\n%!" Response.pp_hum response;
    exit 1


let error_handler (error: Client_connection.error) =
  (* There was an error handling the request. In this simple example, we don't
   * try too hard to understand it. Just print to stderr and exit with an
   * unsuccessful status code. *)
  let msg = match error with
    | `Exn exn -> !% "Exn: %s" (Printexc.to_string exn)
    | `Protocol_error (code, s) ->
       !%"protocol error [%s] %s" (Error_code.to_string code) s
    | _ -> "other"
  in
  Format.eprintf "Unsuccessful request: '%s'!\n%!" msg;
  exit 1

let get host path _query =
  Lwt_unix.getaddrinfo host "443" [ Unix.(AI_FAMILY PF_INET) ] >>= fun addresses ->
  (* Once the address for the host we want to contact has been resolved, we
   * need to create the socket through which the communication with the
   * remote host is going to happen. *)
  let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  (* Then, we connect to the socket we just created, on the address we have
   * previously obtained through name resolution. *)
  Lwt_unix.connect socket (List.hd addresses).Unix.ai_addr >>= fun () ->
  let request =
    Request.create
      `GET
      path
      (* a scheme pseudo-header is required in HTTP/2 requests, otherwise
       * the request will be considered malformed. In our case, we're
       * making a request over HTTPS, so we specify "https" *)
      ~scheme:"https"
      ~headers:
      (* The `:authority` pseudo-header is a blurry line in the HTTP/2
       * specificiation. It's not strictly required but most
       * implementations treat a request with a missing `:authority`
       * pseudo-header as malformed. That is the case for example.com, so
       * we include it. *)
      Headers.(add_list empty [ ":authority", host ])
  in
  let response_received, notify_response_received = Lwt.wait () in
  let response_handler = response_handler notify_response_received in
  Client.TLS.create_connection_with_default ~error_handler socket
  >>= fun connection ->
  let request_body =
    Client.TLS.request connection request ~error_handler ~response_handler
  in
  (* The `request` function returns a request body that we can write to,
   * but in our case just the headers are sufficient. We close the request
   * body immediately to signal to the underlying HTTP/2 framing layer that
   * we're done sending our request. *)
  Body.Writer.close request_body;
  (* Our call to `Lwt_main.run` above will wait until this promise is
   * filled  before exiting the program. *)
  response_received
*)
