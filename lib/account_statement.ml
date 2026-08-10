open Common

type address = {
  (* 預入用アドレス *)
  type_ : string; [@key "type"] (* 通常は "NORMAL" *)
  currency_code : string;
  address : string;
}
[@@deriving yojson]

let address_of_json json =
  match address_of_yojson json with
  | Ok address -> address
  | Error msg -> failwith (!%"Account_statement.address_of_json: %s" msg)

let addresses_of_json json = Json.Util.to_list json |> List.map address_of_json

let getaddresses auth =
  let path = "/v1/me/getaddresses" in
  ApiCommon.get auth path [] |> Lwt.map addresses_of_json

let pagination_query ?count ?before ?after () =
  []
  |> list_add_opt (Option.map (fun c -> ("count", !%"%d" c)) count)
  |> list_add_opt (Option.map (fun x -> ("before", !%"%d" x)) before)
  |> list_add_opt (Option.map (fun x -> ("after", !%"%d" x)) after)

(* 仮想通貨預入履歴 *)
type coin_in = {
  id : int;
  order_id : string;
  currency_code : string;
  amount : float;
  address : string;
  tx_hash : string;
  status : string; (* "PENDING" | "COMPLETED" *)
  event_date : string;
}
[@@deriving yojson]

let coin_in_of_json json =
  match coin_in_of_yojson json with
  | Ok coin_in -> coin_in
  | Error msg -> failwith (!%"Account_statement.coin_in_of_json: %s" msg)

let coin_ins_of_json json = Json.Util.to_list json |> List.map coin_in_of_json

let getcoinins auth ?count ?before ?after () =
  let path = "/v1/me/getcoinins" in
  let query = pagination_query ?count ?before ?after () in
  ApiCommon.get auth path query |> Lwt.map coin_ins_of_json

(* 仮想通貨送付履歴 *)
type coin_out = {
  id : int;
  order_id : string;
  currency_code : string;
  amount : float;
  address : string;
  tx_hash : string;
  fee : float;
  additional_fee : float;
  status : string; (* "PENDING" | "COMPLETED" *)
  event_date : string;
}
[@@deriving yojson]

let coin_out_of_json json =
  match coin_out_of_yojson json with
  | Ok coin_out -> coin_out
  | Error msg -> failwith (!%"Account_statement.coin_out_of_json: %s" msg)

let coin_outs_of_json json = Json.Util.to_list json |> List.map coin_out_of_json

let getcoinouts auth ?count ?before ?after () =
  let path = "/v1/me/getcoinouts" in
  let query = pagination_query ?count ?before ?after () in
  ApiCommon.get auth path query |> Lwt.map coin_outs_of_json

(* 銀行口座一覧 (出金時に指定するidを含む) *)
type bank_account = {
  id : int;
  is_verified : bool;
  bank_name : string;
  branch_name : string;
  account_type : string;
  account_number : string;
  account_name : string;
}
[@@deriving yojson]

let bank_account_of_json json =
  match bank_account_of_yojson json with
  | Ok bank_account -> bank_account
  | Error msg -> failwith (!%"Account_statement.bank_account_of_json: %s" msg)

let bank_accounts_of_json json =
  Json.Util.to_list json |> List.map bank_account_of_json

let getbankaccounts auth =
  let path = "/v1/me/getbankaccounts" in
  ApiCommon.get auth path [] |> Lwt.map bank_accounts_of_json

(* 入金履歴 *)
type deposit = {
  id : int;
  order_id : string;
  currency_code : string;
  amount : float;
  status : string; (* "PENDING" | "COMPLETED" *)
  event_date : string;
}
[@@deriving yojson]

let deposit_of_json json =
  match deposit_of_yojson json with
  | Ok deposit -> deposit
  | Error msg -> failwith (!%"Account_statement.deposit_of_json: %s" msg)

let deposits_of_json json = Json.Util.to_list json |> List.map deposit_of_json

let getdeposits auth ?count ?before ?after () =
  let path = "/v1/me/getdeposits" in
  let query = pagination_query ?count ?before ?after () in
  ApiCommon.get auth path query |> Lwt.map deposits_of_json

(* 出金履歴 (出金の実行そのもの(POST /v1/me/withdraw)は未実装) *)
type withdrawal = {
  id : int;
  order_id : string;
  currency_code : string;
  amount : float;
  status : string; (* "PENDING" | "COMPLETED" *)
  event_date : string;
}
[@@deriving yojson]

let withdrawal_of_json json =
  match withdrawal_of_yojson json with
  | Ok withdrawal -> withdrawal
  | Error msg -> failwith (!%"Account_statement.withdrawal_of_json: %s" msg)

let withdrawals_of_json json =
  Json.Util.to_list json |> List.map withdrawal_of_json

let getwithdrawals auth ?count ?before ?after ?message_id () =
  let path = "/v1/me/getwithdrawals" in
  let query =
    pagination_query ?count ?before ?after ()
    |> list_add_opt (Option.map (fun s -> ("message_id", s)) message_id)
  in
  ApiCommon.get auth path query |> Lwt.map withdrawals_of_json
