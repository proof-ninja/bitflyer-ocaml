let default_filename = "bitflyer-auth.conf"

type t = {
    api_key : string;
    secret : string;
}

let from_file ?(filename=default_filename) () =
  let ch = open_in filename in
  let api_key = input_line ch in
  let secret = input_line ch in
  close_in ch;
  {api_key; secret}

let sign auth timestamp method_ path body =
  let text = Datetime.to_string timestamp ^ method_ ^ path ^ body in
  let secret = auth.secret in
  Hacl_star.EverCrypt.HMAC.mac ~alg:SHA2_256
    ~key:(Bytes.of_string secret) ~msg:(Bytes.of_string text)
  |> Hex.of_bytes
  |> Hex.show


let make_header auth timestamp meth path body =
    let s = sign auth timestamp meth path body in
    [
      ("ACCESS-KEY", auth.api_key);
      ("ACCESS-TIMESTAMP", Datetime.to_string timestamp);
      ("ACCESS-SIGN", s);
      ("Content-Type", "application/json");
    ]
