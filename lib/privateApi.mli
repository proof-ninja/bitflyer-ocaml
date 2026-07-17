open Common

(* 資産残高を取得 *)
val getbalance : Auth.t -> Assets.balance list Lwt.t

(* 新規注文を出す *)
val sendchildorder :
  Auth.t -> product_code -> order_type -> side -> float -> Json.t Lwt.t

val getchildorders :
  Auth.t -> ?child_order_state:string -> ?count:int -> ?before:int ->
  ?after:int -> product_code -> (Json.t * Child_order.placed_order list) Lwt.t

val getexecutions :
  Auth.t -> ?count:int -> ?before:int -> ?after:int -> product_code
  -> Trade.execution list Lwt.t

val sendparentorder :
  Auth.t -> Parent_order.special_order -> Json.t Lwt.t

val getparentorders :
  Auth.t -> product_code -> (Json.t * Parent_order.placed_order list) Lwt.t

val getparentorder :
  Auth.t -> string -> Json.t Lwt.t

val cancelchildorder :
  Auth.t -> product_code -> string -> Json.t Lwt.t

(* 建玉の一覧を取得 *)
val getpositions :
  Auth.t -> product_code -> Trade.position list Lwt.t

(* 取引手数料を取得 *)
val gettradingcommission :
  Auth.t -> product_code -> float Lwt.t

(* 預入用アドレス取得 *)
val getaddresses :
  Auth.t -> Account_statement.address list Lwt.t
