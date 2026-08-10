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
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune cohttp lwt cohttp-lwt-unix yojson ppx_deriving_yojson hacl-star hex dolog lwt_ppx websocket-lwt-unix ipaddr)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
