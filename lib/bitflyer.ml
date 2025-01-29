open Lwt
open Common

let buy auth currency_pair ?(order=Market) amount =
  Lwt_main.run begin
      PrivateApi.sendchildorder auth currency_pair order Buy amount
      >>= fun json -> Log.debug "buy: %s" (Json.to_string json); Lwt.return ()
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
      >>= fun json -> Log.debug "order: %s" (Json.to_string json); Lwt.return ()
    end

module Datetime = Datetime

module Log = Log

module Auth = Auth

module PublicApi = PublicApi

module PrivateApi = PrivateApi
