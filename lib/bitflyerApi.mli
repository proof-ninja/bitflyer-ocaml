open Common

val getticker : product_code -> Ticker.response Lwt.t

val getbalance : Auth.t -> Json.t Lwt.t

val sendchildorder :
  Auth.t -> product_code -> Common.order_type -> string -> float -> Json.t Lwt.t

val getchildorders :
  Auth.t -> product_code -> Trade.order list Lwt.t

val getexecutions :
  Auth.t -> product_code -> Trade.execution list Lwt.t
