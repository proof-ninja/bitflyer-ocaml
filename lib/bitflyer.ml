open Lwt
open Common

let buy auth currency_pair ?(order=Market) amount =
  Lwt_main.run begin
      PrivateApi.sendchildorder auth currency_pair order Buy amount
      >>= fun _json -> Lwt.return ()
    end

let get_executions auth currency_pair =
  Lwt_main.run begin
      PrivateApi.getexecutions auth currency_pair
    end

let ifd_buysell auth currency_pair (price1, amount1) (price2, amount2) =
  let open Parent_order in
  let order = Parent_order.make_ifd_order currency_pair
                (Buy, Limit price1, amount1) (Sell, Limit price2, amount2)
  in
  Lwt_main.run begin
      PrivateApi.sendparentorder auth order
      >>= fun _json -> Lwt.return ()
    end

(* Commonモジュール全体(list_take等の内部ユーティリティを含む)は公開せず、
   外部から発注する際に必要なside/order_typeの2つの型だけを再公開する。 *)
type side = Common.side = Buy | Sell
type order_type = Common.order_type = Market | Limit of float

module Datetime = Datetime

module Auth = Auth

module Assets = Assets

module Child_order = Child_order

module PublicApi = PublicApi

module PrivateApi = PrivateApi

module Realtime = Realtime
