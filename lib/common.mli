type order =
  | Market
  | Limit of int

val (!%) :  ('a, unit, string) format -> 'a

type side = Buy | Sell

val host : string
