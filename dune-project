(lang dune 3.4)

(name bitflyer)

(version dev)

(generate_opam_files true)

(source
 (github proof-ninja/bitflyer-ocaml))

(authors "Yoshihiro Imai")

(maintainers "Yoshihiro Imai")

(license MIT)

(documentation https://github.com/proof-ninja/bitflyer-ocaml/)

(package
 (name bitflyer)
 (synopsis "OCaml client for the bitFlyer cryptocurrency exchange API")
 (description
  "Provides typed bindings to bitFlyer's public and private HTTP APIs (market data, orders, positions, account statements) and the realtime WebSocket API (ticker, orderboard, executions, and authenticated order-event channels). Handles HMAC-SHA256 request signing and rate limiting automatically.")
 (depends
  (ocaml
   (>= "4.14"))
  dune
  cohttp
  lwt
  cohttp-lwt-unix
  yojson
  ppx_deriving_yojson
  (hacl-star
   (>= "0.7.2"))
  hex
  dolog
  lwt_ppx
  (websocket-lwt-unix
   (>= "2.17"))
  ipaddr)
 (tags
  ("cryptocurrency" "exchange" "trading" "api" "websocket")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
