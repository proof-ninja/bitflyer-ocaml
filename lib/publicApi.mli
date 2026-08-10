open Common

val getmarkets : Json.t Lwt.t
val markets : Json.t Lwt.t

type level = { price : float; size : float }
type board = { mid_price : float; bids : level list; asks : level list }

val board_of_json : Json.t -> board
val board_to_yojson : board -> Json.t
val getboard : product_code -> board Lwt.t
val board : product_code -> board Lwt.t

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

val ticker_of_json : Json.t -> ticker
val ticker : product_code -> ticker Lwt.t
val getticker : product_code -> ticker Lwt.t
val getexecutions : product_code -> Json.t Lwt.t
val executions : product_code -> Json.t Lwt.t
val getboardstate : product_code -> Json.t Lwt.t
val gethealth : product_code -> string Lwt.t
val getchats : product_code -> Json.t Lwt.t

type funding_rate = {
  current_funding_rate : float;
  next_funding_rate_settledate : string;
}

val funding_rate_of_json : Json.t -> funding_rate
val getfundingrate : product_code -> funding_rate Lwt.t

type funding_rate_history_entry = {
  calculation_date : string;
  settlement_date : string;
  rate : float;
}

(* [from_]/[to_]: 期間の開始/終了日時 (ISO8601)。[count]: 最大500件、省略時100件。 *)
val getfundingratehistory :
  ?from_:string ->
  ?to_:string ->
  ?count:int ->
  product_code ->
  funding_rate_history_entry list Lwt.t

type corporate_leverage = {
  current_max : float;
  current_startdate : string;
  next_max : float option;
  next_startdate : string option;
}

val getcorporateleverage : unit -> corporate_leverage Lwt.t
