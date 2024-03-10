type product_code = string

type order_type =
  | Market
  | Limit of float

val (!%) :  ('a, unit, string) format -> 'a

type side = Buy | Sell
val side_of_string : string -> side

module Log = Dolog.Log
module Json = Yojson.Basic
