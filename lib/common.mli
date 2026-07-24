val (!%) :  ('a, unit, string) format -> 'a

val list_take : int -> 'a list -> 'a list

val list_group_by : ('a -> 'b) -> 'a list -> ('b * 'a list) list

val list_reduce : ('a -> 'a -> 'a) -> 'a list -> 'a

val list_drop_while : ('a -> bool) -> 'a list -> 'a list

val list_find_and_rest : ('a -> bool) -> 'a list -> ('a * 'a list) option

val list_is_empty : 'a list -> bool

val list_last : 'a list -> 'a

val list_add_opt : 'a option -> 'a list -> 'a list

type product_code = string

type order_type =
  | Market
  | Limit of float
val string_of_order_type : order_type -> string

module Json = Yojson.Safe

type side = Buy | Sell
val side_of_string : string -> side
val string_of_side : side -> string
val side_to_yojson : side -> Json.t
val side_of_yojson : Json.t -> (side, string) result
