val (!%) :  ('a, unit, string) format -> 'a

val list_take : int -> 'a list -> 'a list

type product_code = string

type order_type =
  | Market
  | Limit of float
val string_of_order_type : order_type -> string

type side = Buy | Sell
val side_of_string : string -> side
val string_of_side : side -> string

module Log = Dolog.Log
module Json = Yojson.Basic
