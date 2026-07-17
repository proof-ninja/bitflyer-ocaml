open Common

type balance = {
    currency_code : string;
    amount : float;
    available : float; (*買付余力*)
} [@@deriving yojson]

let balance_of_json json =
  match balance_of_yojson json with
  | Ok balance -> balance
  | Error msg -> failwith (!%"Assets.balance_of_json: %s" msg)

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
