(*open Lwt*)
(*open Yojson*)
(*open Common*)

(*let sign timestamp method_ path body =
  let text = time_to_string timestamp ^ method_ ^ path ^ body in
  let secret = Config.secret in
  Hacl_star.EverCrypt.HMAC.mac ~alg:SHA2_256
    ~key:(Bytes.of_string secret) ~msg:(Bytes.of_string text)
  |> Hex.of_bytes
  |> Hex.show
*)

let getbalance auth =
  let path = "/v1/me/getbalance" in
  let timestamp = Datetime.now () in
  let headers = Auth.make_header auth timestamp "GET" path "" in
  Http.get ~headers Common.host path []
