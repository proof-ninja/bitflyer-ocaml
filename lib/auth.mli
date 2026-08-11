type t

val make_header : t -> string -> string -> string -> (string * string) list
val from_file : ?filename:string -> unit -> t
val auth : unit -> t
val api_key : t -> string

(* Realtime API(WebSocket)のプライベートチャンネル購読に使う認証署名。
   REST APIの[make_header]/[sign]がtimestamp+method+path+bodyを署名するのに対し、
   こちらはtimestamp+nonceを署名する(bitFlyer公式ドキュメントの仕様)。 *)
val sign_realtime : t -> timestamp:int -> nonce:string -> string
