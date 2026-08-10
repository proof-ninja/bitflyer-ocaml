open Common

(* 資産残高を取得 *)
val getbalance : Auth.t -> Assets.balance list Lwt.t

(* 新規注文を出す *)
val sendchildorder :
  Auth.t -> product_code -> order_type -> side -> float -> Json.t Lwt.t

val getchildorders :
  Auth.t ->
  ?child_order_state:string ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  product_code ->
  (Json.t * Child_order.placed_order list) Lwt.t

val getexecutions :
  Auth.t ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  product_code ->
  Trade.execution list Lwt.t

val sendparentorder : Auth.t -> Parent_order.special_order -> Json.t Lwt.t

val getparentorders :
  Auth.t -> product_code -> (Json.t * Parent_order.placed_order list) Lwt.t

val getparentorder : Auth.t -> string -> Json.t Lwt.t
val cancelchildorder : Auth.t -> product_code -> Trade.order_ref -> Json.t Lwt.t

(* 親注文をキャンセルする *)
val cancelparentorder :
  Auth.t -> product_code -> Trade.order_ref -> Json.t Lwt.t

(* すべての注文をキャンセルする *)
val cancelallchildorders : Auth.t -> product_code -> Json.t Lwt.t

(* 建玉の一覧を取得 *)
val getpositions : Auth.t -> product_code -> Trade.position list Lwt.t

(* 取引手数料を取得 *)
val gettradingcommission : Auth.t -> product_code -> float Lwt.t

(* 預入用アドレス取得 *)
val getaddresses : Auth.t -> Account_statement.address list Lwt.t

(* 証拠金の状態を取得 *)
val getcollateral : Auth.t -> Assets.collateral_status Lwt.t

(* 証拠金の数量（通貨別）を取得 *)
val getcollateralaccount : Auth.t -> Assets.collateral_account list Lwt.t

(* 仮想通貨預入履歴 *)
val getcoinins :
  Auth.t ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  unit ->
  Account_statement.coin_in list Lwt.t

(* 仮想通貨送付履歴 *)
val getcoinouts :
  Auth.t ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  unit ->
  Account_statement.coin_out list Lwt.t

(* 銀行口座一覧取得 *)
val getbankaccounts : Auth.t -> Account_statement.bank_account list Lwt.t

(* 入金履歴 *)
val getdeposits :
  Auth.t ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  unit ->
  Account_statement.deposit list Lwt.t

(* 出金履歴 (出金の実行そのもの(POST /v1/me/withdraw)は未実装) *)
val getwithdrawals :
  Auth.t ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  ?message_id:string ->
  unit ->
  Account_statement.withdrawal list Lwt.t

(* 残高履歴を取得 *)
val getbalancehistory :
  Auth.t ->
  ?currency_code:string ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  unit ->
  Trade.balance_history_entry list Lwt.t

(* 証拠金の変動履歴を取得 *)
val getcollateralhistory :
  Auth.t ->
  ?count:int ->
  ?before:int ->
  ?after:int ->
  unit ->
  Trade.collateral_history_entry list Lwt.t

(* このAPIキーで呼出可能なHTTP Private APIのpathの一覧を取得する *)
val getpermissions : Auth.t -> string list Lwt.t
