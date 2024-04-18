open Common

val getmarkets : Json.t Lwt.t
val markets : Json.t Lwt.t

val getboard : product_code -> Json.t Lwt.t
val board : product_code -> Json.t Lwt.t

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

val ticker : product_code -> ticker Lwt.t
val getticker : product_code -> ticker Lwt.t

val getexecutions : product_code -> Json.t Lwt.t
val executions : product_code -> Json.t Lwt.t

val getboardstate : product_code -> Json.t Lwt.t

val gethealth : product_code -> string Lwt.t

val getchats : product_code -> Json.t Lwt.t
