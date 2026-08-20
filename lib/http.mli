exception HttpException of string * Uri.t * exn
exception ApiError of string * Uri.t * Cohttp.Code.status_code * string

val get :
  ?log:(string -> unit) ->
  ?headers:(string * string) list ->
  Uri.t ->
  string Lwt.t

val post :
  ?log:(string -> unit) ->
  ?headers:(string * string) list ->
  Uri.t ->
  string ->
  string Lwt.t
