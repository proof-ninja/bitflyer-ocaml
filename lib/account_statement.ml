open Common

type address = { (* 預入用アドレス *)
    type_: string [@key "type"]; (* 通常は "NORMAL" *)
    currency_code: string;
    address: string;
} [@@deriving yojson]

let address_of_json json =
  match address_of_yojson json with
  | Ok address -> address
  | Error msg -> failwith (!%"Account_statement.address_of_json: %s" msg)

let addresses_of_json json =
  Json.Util.to_list json
  |> List.map address_of_json

let getaddresses auth =
  let path = "/v1/me/getaddresses" in
  ApiCommon.get auth path []
  |> Lwt.map addresses_of_json
