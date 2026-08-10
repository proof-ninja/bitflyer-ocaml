open Common

type balance = {
  currency_code : string;
  amount : float;
  available : float; (*買付余力*)
}
[@@deriving yojson]

let balance_of_json json =
  match balance_of_yojson json with
  | Ok balance -> balance
  | Error msg -> failwith (!%"Assets.balance_of_json: %s" msg)

let balances_of_json json = Json.Util.to_list json |> List.map balance_of_json

let getbalance auth =
  let path = "/v1/me/getbalance" in
  ApiCommon.get auth path [] |> Lwt.map balances_of_json

type collateral_status = {
  collateral : float;
  open_position_pnl : float;
  require_collateral : float;
  keep_rate : float;
  margin_call_amount : float;
  margin_call_due_date : string;
}
[@@deriving yojson]

let collateral_status_of_json json =
  match collateral_status_of_yojson json with
  | Ok status -> status
  | Error msg -> failwith (!%"Assets.collateral_status_of_json: %s" msg)

let getcollateral auth =
  let path = "/v1/me/getcollateral" in
  ApiCommon.get auth path [] |> Lwt.map collateral_status_of_json

type collateral_account = { currency_code : string; amount : float }
[@@deriving yojson]

let collateral_account_of_json json =
  match collateral_account_of_yojson json with
  | Ok account -> account
  | Error msg -> failwith (!%"Assets.collateral_account_of_json: %s" msg)

let collateral_accounts_of_json json =
  Json.Util.to_list json |> List.map collateral_account_of_json

let getcollateralaccount auth =
  let path = "/v1/me/getcollateralaccounts" in
  ApiCommon.get auth path [] |> Lwt.map collateral_accounts_of_json
