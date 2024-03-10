open Common

val get_public : string -> (string * string) list -> Json.t Lwt.t
val get : Auth.t -> string -> (string * string) list -> Json.t Lwt.t
val post : Auth.t -> string -> string -> Json.t Lwt.t
