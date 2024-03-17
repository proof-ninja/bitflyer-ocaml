open Lwt
open Common

(* HTTP Public APIs *)

let getmarkets =
  let path = "/v1/getmarkets" in
  ApiCommon.get_public path []

let markets =
  let path = "/v1/markets" in
  ApiCommon.get_public path []

(*
{
  "mid_price": 33320,
  "bids": [
    {"price": 30000, "size": 0.1},
    {"price": 25570, "size": 3}
  ],
  "asks": [
    {"price": 36640, "size": 5},
    {"price": 36700, "size": 1.2}
  ]
}*)
let getboard product_code =
  let path = "/v1/getboard" in
  ApiCommon.get_public path [("product_code", product_code)]

let board product_code =
  let path = "/v1/board" in
  ApiCommon.get_public path [("product_code", product_code)]

type ticker = {
    product_code: string;
    (*TODO: "state": "RUNNING",*)
    timestamp: string;
    (*TODO: "tick_id": 3579,*)
    best_bid: float;
    best_ask: float;
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
  {
    product_code;
    timestamp;
    best_bid;
    best_ask;
  }

let getticker product_code =
  let path = "/v1/getticker" in
  let query = [("product_code", product_code)] in
  ApiCommon.get_public path query >>= fun json ->
  Lwt.return (ticker_of_json json)

let ticker product_code =
  let path = "/v1/ticker" in
  let query = [("product_code", product_code)] in
  ApiCommon.get_public path query >>= fun json ->
  Lwt.return (ticker_of_json json)

let getexecutions product_code =
  let query = [("product_code", product_code)] in
  let path = "/v1/getexecutions" in
  ApiCommon.get_public path query

let executions product_code =
  let query = [("product_code", product_code)] in
  let path = "/v1/executions" in
  ApiCommon.get_public path query

let getboardstate product_code =
  let query = [("product_code", product_code)] in
  let path = "/v1/getboardstate" in
  ApiCommon.get_public path query

let gethealth product_code =
  let query = [("product_code", product_code)] in
  let path = "/v1/gethealth" in
  ApiCommon.get_public path query
  |> Lwt.map (fun json -> Json.Util.(member "status" json |> to_string))

let getchats product_code =
  let query = [("from_date", product_code)] in
  let path = "/v1/getchats" in
  ApiCommon.get_public path query
