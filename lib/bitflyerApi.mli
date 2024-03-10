val getticker : string -> string -> string Lwt.t

val sendchildorder :
  Auth.t -> string -> Common.order -> string -> float -> string Lwt.t
