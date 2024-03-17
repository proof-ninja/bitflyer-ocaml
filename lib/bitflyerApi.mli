open Common

val getmarkets : Json.t Lwt.t
val markets : Json.t Lwt.t

val getboard : product_code -> Json.t Lwt.t
val board : product_code -> Json.t Lwt.t

val getexecutions : product_code -> Json.t Lwt.t
val executions : product_code -> Json.t Lwt.t

val getboardstate : product_code -> Json.t Lwt.t

val gethealth : product_code -> string Lwt.t

val getchats : product_code -> Json.t Lwt.t

val getticker : product_code -> Public.ticker Lwt.t
val ticker : product_code -> Public.ticker Lwt.t

val getbalance : Auth.t -> Assets.balance list Lwt.t

val me_sendchildorder :
  Auth.t -> product_code -> order_type -> side -> float -> Json.t Lwt.t

val me_getchildorders :
  Auth.t -> product_code -> Trade.order list Lwt.t

val me_getexecutions :
  Auth.t -> product_code -> Trade.execution list Lwt.t
