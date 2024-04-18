open Common

(* 資産残高を取得 *)
val getbalance : Auth.t -> Assets.balance list Lwt.t

(* 新規注文を出す *)
val sendchildorder :
  Auth.t -> product_code -> order_type -> side -> float -> Json.t Lwt.t

val getchildorders :
  Auth.t -> product_code -> Trade.order list Lwt.t

val getexecutions :
  Auth.t -> product_code -> Trade.execution list Lwt.t
