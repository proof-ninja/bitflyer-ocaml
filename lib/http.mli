exception HttpException of string * Uri.t * exn

val get : ?log:(string -> unit) ->
          ?headers:(string * string) list -> Uri.t -> string Lwt.t

val post : ?log:(string -> unit) ->
           ?headers:(string * string) list -> Uri.t -> string -> string Lwt.t
