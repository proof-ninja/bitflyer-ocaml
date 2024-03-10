open Lwt
open Common

type response = {
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

let response_of_json json =
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
  Lwt.return (response_of_json json)
