type order =
  | Market (* 成行注文 *)
  | Limit of int (* 指値注文 *)

type side = Buy | Sell

let (!%) s = Printf.sprintf s
module Log = Dolog.Log

let host = "api.bitflyer.com"
