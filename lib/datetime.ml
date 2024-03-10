type t = float

let now () = Unix.gettimeofday ()

let to_string time = (time *. 1000.) |> int_of_float |> string_of_int
