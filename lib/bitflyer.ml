open Lwt
open Common

let example () = Http.get "example.com" "/" []

let buy auth currency_pair ?(order=Market) amount =
  Lwt_main.run begin
      BitflyerApi.sendchildorder auth currency_pair order "BUY" amount
      >>= fun text -> print_endline text; Lwt.return ()
    end

module Auth = Auth
