let (!%) s = Printf.sprintf s

let list_take n xs =
  List.to_seq xs |> Seq.take n |> List.of_seq

type product_code = string

type order_type =
  | Market (* 成行注文 *)
  | Limit of float (* 指値注文 *)

let string_of_order_type = function
| Market -> "M"
| Limit price -> !%"Limit %f" price

type side = Buy | Sell

let side_of_string = function
  | "BUY" -> Buy
  | "SELL" -> Sell
  | other -> failwith (!%"Common.side_of_string: '%s'" other)

let string_of_side = function
  | Buy -> "BUY"
  | Sell -> "SELL"

module Log = Dolog.Log

module Json = Yojson.Basic
