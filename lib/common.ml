let (!%) s = Printf.sprintf s

type product_code = string

type order_type =
  | Market (* 成行注文 *)
  | Limit of float (* 指値注文 *)

type side = Buy | Sell

let side_of_string = function
  | "BUY" -> Buy
  | "SELL" -> Sell
  | other -> failwith (!%"Common.side_of_string: '%s'" other)

module Log = Dolog.Log

module Json = Yojson.Basic
