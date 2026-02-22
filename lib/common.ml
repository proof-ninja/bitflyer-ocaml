let (!%) s = Printf.sprintf s

let list_take n xs =
  List.to_seq xs |> Seq.take n |> List.of_seq


let list_upsert_assoc key value dict =
  (key, value) :: List.remove_assoc key dict

let list_group_by f xs =
  List.fold_left (fun dict x ->
      let key = f x in
      match List.assoc_opt key dict with
      | None -> (key, [x]) :: dict
      | Some ys -> list_upsert_assoc key (x :: ys) dict) [] xs
  |> List.map (fun (key, values) -> (key, List.rev values))
  |> List.rev

let list_reduce f xs =
  match xs with
  | [] -> failwith "Common.list_reduce: empty"
  | x0 :: xs ->
     List.fold_left f x0 xs

let rec list_drop_while f xs =
  match xs with
  | [] -> []
  | x :: xs when f x -> list_drop_while f xs
  | _ :: _ -> xs

let list_find_and_rest f xs =
  match List.find_opt f xs with
  | None -> None
  | Some x ->
     Some (x, List.filter (fun y -> x <> y) xs)

let list_is_empty = function
  | [] -> true
  | _ :: _ -> false

let list_last xs =
  if list_is_empty xs then failwith (!%"Common.list_last: list is empty");
  List.hd @@ List.rev xs

let list_add_opt o xs =
  match o with
  | Some x -> x :: xs
  | None -> xs


type product_code = string

type order_type =
  | Market (* 成行注文 *)
  | Limit of float (* 指値注文 *)

let string_of_order_type = function
| Market -> "M"
| Limit price -> !%"Limit %f" price

type side = Buy | Sell

let side_of_string = function
  | "BUY" -> Buy
  | "SELL" -> Sell
  | other -> failwith (!%"Common.side_of_string: '%s'" other)

let string_of_side = function
  | Buy -> "BUY"
  | Sell -> "SELL"

module Log = Dolog.Log

module Json = Yojson.Basic
