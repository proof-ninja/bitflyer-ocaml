val get : ?headers:(string * string) list ->
          string -> string -> (string * string) list -> string Lwt.t

val post : ?headers:(string* string) list ->
           string -> string -> string -> string Lwt.t
