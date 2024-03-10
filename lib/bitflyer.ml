open Lwt
open Common

let buy auth currency_pair ?(order=Market) amount =
  Lwt_main.run begin
      BitflyerApi.sendchildorder auth currency_pair order "BUY" amount
      >>= fun json -> Log.debug "buy: %s" (Json.to_string json); Lwt.return ()
    end

module Log = Log

module Auth = Auth

module BitflyerApi = BitflyerApi
