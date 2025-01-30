open Common

type special_order_type =
| Limit of float (*指値注文*)
| Market (* 成り行き注文*)
| Stop of float  (*ストップ注文*)
| Stop_limit of {price: float; trigger_price: float}(*ストップ・リミット注文*)
| Trail of {offset: int} (*トレーリングストップ注文, トレール幅を正の整数で指定します*)

let label_of_type = function
  | Limit _ -> "LIMIT"
  | Market -> "MARKET"
  | Stop _ -> "STOP"
  | Stop_limit _ -> "STOP_LIMIT"
  | Trail _ -> "TRAIL"


type simple_order = {
    product_code: string;
    condition_type: special_order_type;
    side: side;
    size: float;
  }

let make_simple product_code condition_type side size =
  {product_code; condition_type; side; size}

type order_method =
  | Simple of simple_order
  | IFD of simple_order * simple_order
  | OCO of simple_order * simple_order
  | IFDOCO of simple_order * simple_order * simple_order

let label_of_method = function
  | Simple _ -> "SIMPLE"
  | IFD _ -> "IFD"
  | OCO _ -> "OCO"
  | IFDOCO _ -> "IFDOCO"

type special_order = {
    minute_to_expire: int option; (*second*)
    time_in_force: string option;
    order_method: order_method;
  }

let make_ifd_order product_code (side1, typ1, size1) (side2, typ2, size2) =
  let order1 = make_simple product_code typ1 side1 size1 in
  let order2 = make_simple product_code typ2 side2 size2 in
  {minute_to_expire=None; time_in_force=None; order_method=IFD (order1, order2)}

let json_of_opt_assocs assocs =
  (List.filter_map (fun (k, vopt) -> Option.map (fun v -> (k,v)) vopt) assocs)
  |> fun assocs -> `Assoc assocs


let json_of_simple_order simple : Json.t =
  match simple.condition_type with
  | Limit price ->
     `Assoc [
         ("product_code", `String simple.product_code);
         ("condition_type", `String (label_of_type  simple.condition_type));
         ("side", `String (string_of_side simple.side));
         ("price", `Float price);
         ("size", `Float simple.size);
       ]
  | Market ->
     `Assoc [
         ("product_code", `String simple.product_code);
         ("condition_type", `String (label_of_type  simple.condition_type));
         ("side", `String (string_of_side simple.side));
         ("size", `Float simple.size);
       ]
  | Stop trigger_price ->
     `Assoc [
         ("product_code", `String simple.product_code);
         ("condition_type", `String (label_of_type  simple.condition_type));
         ("side", `String (string_of_side simple.side));
         ("trigger_price", `Float trigger_price);
         ("size", `Float simple.size);
       ]
  | Stop_limit {price; trigger_price} ->
     `Assoc [
         ("product_code", `String simple.product_code);
         ("condition_type", `String (label_of_type  simple.condition_type));
         ("side", `String (string_of_side simple.side));
         ("price", `Float price);
         ("trigger_price", `Float trigger_price);
         ("size", `Float simple.size);
       ]
  | Trail {offset} ->
     `Assoc [
         ("product_code", `String simple.product_code);
         ("condition_type", `String (label_of_type  simple.condition_type));
         ("side", `String (string_of_side simple.side));
         ("size", `Float simple.size);
         ("offset", `Int offset);
       ]


let json_of_order (order: special_order) : Json.t =
  let parameters =
    match order.order_method with
    | Simple simple -> [json_of_simple_order simple]
    | IFD (s1, s2) -> List.map json_of_simple_order [s1; s2]
    | OCO (s1, s2) -> List.map json_of_simple_order [s1; s2]
    | IFDOCO (s1, s2, s3) ->
       List.map json_of_simple_order [s1; s2; s3]
  in
  json_of_opt_assocs [
      ("order_method", Some (`String (label_of_method order.order_method)));
      ("minute_of_expired", Option.map (fun e -> `Int e) order.minute_to_expire);
      ("time_in_force", Option.map (fun t -> `String t) order.time_in_force);
      ("parameters", Some (`List parameters))
    ]

type placed_order = { (* 発注済みの注文 *)
    id: int;
    (*    "parent_order_id": "JCO20150707-084555-022523", *)
    product_code: string;
    (*side: side; "BUYSELL" *)
    (* "parent_order_type": "STOP",*)
    price: float;
    average_price: float;
    size: float;
    parent_order_state: string;
    (*"expire_date": "2015-07-14T07:25:52",*)
    (*"parent_order_date": "2015-07-07T08:45:53",*)
    (*"parent_order_acceptance_id": "JRF20150707-084552-031927",*)
    (*"outstanding_size": 0,*)
    (*"cancel_size": 0,*)
    (*"executed_size": 0.1,*)
    (*"total_commission": 0*)
  }

let order_of_json json =
  let open Json.Util in
  let id = member "id" json |> to_int in
  let product_code = member "product_code" json |> to_string in
  let price = member "price" json |> to_float in
  let average_price = member "average_price" json |> to_float in
  let size = member "size" json |> to_float in
  let parent_order_state = member "parent_order_state" json |> to_string in
  {
    id; product_code; price; average_price; size; parent_order_state;
  }
