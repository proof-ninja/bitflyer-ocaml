type t
val now : unit -> t
val to_millisec : t -> int
val to_sec : t -> float
val from_string : string -> t
val ymdhms : t -> string
val from_sec : float -> t
val sday : t -> string
