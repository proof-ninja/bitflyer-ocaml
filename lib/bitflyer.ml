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

module Datetime = Datetime

module Log = Log

module Auth = Auth

module PublicApi = PublicApi

module PrivateApi = PrivateApi
