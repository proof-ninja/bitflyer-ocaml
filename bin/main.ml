open Bitflyer
module Json = Bitflyer__Common.Json
open Lwt

let auth = Auth.auth ()

let () =
  Log.set_log_level Log.DEBUG;
(*  buy auth "BTC_JPY" 0.001;*)
(*  let latest = get_executions auth "BTC_JPY" |> List.hd in
  ignore latest*)
  try
    Lwt_main.run begin
        PublicApi.getboard "BTC_JPY" >>= fun json ->
        print_endline (Json.show json);
        return ()
end
  with
  | e -> prerr_endline (Printexc.to_string e)
