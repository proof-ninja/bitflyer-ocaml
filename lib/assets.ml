open Common

type balance = {
    currency_code : string;
    amount : float;
    available : float; (*買付余力*)
}

let balance_of_json json =
  let open Json.Util in
  let currency_code = member "currency_code" json |> to_string in
  let amount = member "amount" json |> to_float in
  let available = member "available" json |> to_float in
  { currency_code; amount; available }

let balances_of_json json =
  Json.Util.to_list json
  |> List.map balance_of_json

let getbalance auth =
  let path = "/v1/me/getbalance" in
  ApiCommon.get auth path []
  |> Lwt.map balances_of_json

let getcollateral auth =
  let path = "/v1/me/getcollateral" in
  ApiCommon.get auth path []

let getcollateralaccount auth =
  let path = "/v1/me/getcollateralaccounts" in
  ApiCommon.get auth path []
