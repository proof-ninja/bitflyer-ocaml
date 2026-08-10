open Lwt
open Common

(* HTTP Public APIs *)

let getmarkets =
  let path = "/v1/getmarkets" in
  ApiCommon.get_public path []

let markets =
  let path = "/v1/markets" in
  ApiCommon.get_public path []

type level = { price : float; size : float } [@@deriving yojson]

type board = { mid_price : float; bids : level list; asks : level list }
[@@deriving yojson]

let board_of_json json =
  match board_of_yojson json with
  | Ok board -> board
  | Error msg -> failwith (!%"PublicApi.board_of_json: %s" msg)

let getboard product_code =
  let path = "/v1/getboard" in
  ApiCommon.get_public path [ ("product_code", product_code) ] >>= fun json ->
  Lwt.return (board_of_json json)

let board product_code =
  let path = "/v1/board" in
  ApiCommon.get_public path [ ("product_code", product_code) ] >>= fun json ->
  Lwt.return (board_of_json json)

type ticker = {
  product_code : string;
  (*TODO: "state": "RUNNING",*)
  timestamp : string;
  (*TODO: "tick_id": 3579,*)
  best_bid : float;
  best_ask : float;
      (*TODO: "best_bid_size": 0.1,*)
      (*TODO: "best_ask_size": 5,*)
      (*TODO: "total_bid_depth": 15.13,*)
      (*TODO: "total_ask_depth": 20,*)
      (*TODO: "market_bid_size": 0,*)
      (*TODO: "market_ask_size": 0,*)
      (*TODO: "ltp": 31690,*)
      (*TODO: "volume": 16819.26,*)
      (*TODO: "volume_by_product": 6819.26*)
}

let ticker_of_json json =
  let open Json.Util in
  let product_code = member "product_code" json |> to_string in
  let timestamp = member "timestamp" json |> to_string in
  let best_bid = member "best_bid" json |> to_float in
  let best_ask = member "best_ask" json |> to_float in
  { product_code; timestamp; best_bid; best_ask }

let getticker product_code =
  let path = "/v1/getticker" in
  let query = [ ("product_code", product_code) ] in
  ApiCommon.get_public path query >>= fun json ->
  Lwt.return (ticker_of_json json)

let ticker product_code =
  let path = "/v1/ticker" in
  let query = [ ("product_code", product_code) ] in
  ApiCommon.get_public path query >>= fun json ->
  Lwt.return (ticker_of_json json)

let getexecutions product_code =
  let query = [ ("product_code", product_code) ] in
  let path = "/v1/getexecutions" in
  ApiCommon.get_public path query

let executions product_code =
  let query = [ ("product_code", product_code) ] in
  let path = "/v1/executions" in
  ApiCommon.get_public path query

let getboardstate product_code =
  let query = [ ("product_code", product_code) ] in
  let path = "/v1/getboardstate" in
  ApiCommon.get_public path query

let gethealth product_code =
  let query = [ ("product_code", product_code) ] in
  let path = "/v1/gethealth" in
  ApiCommon.get_public path query
  |> Lwt.map (fun json -> Json.Util.(member "status" json |> to_string))

let getchats product_code =
  let query = [ ("from_date", product_code) ] in
  let path = "/v1/getchats" in
  ApiCommon.get_public path query

type funding_rate = {
  current_funding_rate : float;
  next_funding_rate_settledate : string;
}
[@@deriving yojson]

let funding_rate_of_json json =
  match funding_rate_of_yojson json with
  | Ok funding_rate -> funding_rate
  | Error msg -> failwith (!%"PublicApi.funding_rate_of_json: %s" msg)

let getfundingrate product_code =
  let path = "/v1/getfundingrate" in
  let query = [ ("product_code", product_code) ] in
  ApiCommon.get_public path query >>= fun json ->
  Lwt.return (funding_rate_of_json json)

type funding_rate_history_entry = {
  calculation_date : string;
  settlement_date : string;
  rate : float;
}
[@@deriving yojson]

let funding_rate_history_entry_of_json json =
  match funding_rate_history_entry_of_yojson json with
  | Ok entry -> entry
  | Error msg ->
      failwith (!%"PublicApi.funding_rate_history_entry_of_json: %s" msg)

let funding_rate_history_of_json json =
  Json.Util.to_list json |> List.map funding_rate_history_entry_of_json

(* [from_]/[to_]: 期間の開始/終了日時 (ISO8601)。[count]: 最大500件、省略時100件。 *)
let getfundingratehistory ?from_ ?to_ ?count product_code =
  let path = "/v1/getfundingratehistory" in
  let query =
    [ ("product_code", product_code) ]
    |> list_add_opt (Option.map (fun s -> ("from", s)) from_)
    |> list_add_opt (Option.map (fun s -> ("to", s)) to_)
    |> list_add_opt (Option.map (fun c -> ("count", !%"%d" c)) count)
  in
  ApiCommon.get_public path query >>= fun json ->
  Lwt.return (funding_rate_history_of_json json)

type corporate_leverage = {
  current_max : float;
  current_startdate : string;
  next_max : float option;
  next_startdate : string option;
}
[@@deriving yojson]

let corporate_leverage_of_json json =
  match corporate_leverage_of_yojson json with
  | Ok leverage -> leverage
  | Error msg -> failwith (!%"PublicApi.corporate_leverage_of_json: %s" msg)

let getcorporateleverage () =
  let path = "/v1/getcorporateleverage" in
  ApiCommon.get_public path [] >>= fun json ->
  Lwt.return (corporate_leverage_of_json json)
