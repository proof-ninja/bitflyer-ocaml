open Common

let json_of_order product_code order side size : Json.t =
  match order with
  | Limit price ->
     `Assoc [
         ("product_code", `String product_code);
         ("child_order_type", `String "LIMIT");
         ("price", `String (string_of_float price));
         ("side", `String (string_of_side side));
         ("size", `String (string_of_float size));
       ]
  | Market ->
     `Assoc [
         ("product_code", `String product_code);
         ("child_order_type", `String "MARKET");
         ("side", `String (string_of_side side));
         ("size", `String (string_of_float size));
       ]

type placed_order = { (* 発注済みの注文 *)
    id: int;
    (*"child_order_id": "JOR20150707-084555-022523",*)
    product_code: string;
    side: side;
    child_order_type: order_type;
    (*"average_price": 30000,*)
    size: float;
    child_order_state: string; (*"ACTIVE"とか"COMPLETED"とか*)
    (*"expire_date": "2015-07-14T07:25:52",*)
    child_order_date: Datetime.t; (*"2015-07-07T08:45:53"*)
    (*"child_order_acceptance_id": "JRF20150707-084552-031927",*)
    (* "outstanding_size": 0,*)
    (*"cancel_size": 0,*)
    (*"executed_size": 0.1,*)
    (*"total_commission": 0,*)
    (*"time_in_force": "GTC"*)
  }

let order_of_json json =
  let open Json.Util in
  let id = member "id" json |> to_int in
  let product_code = member "product_code" json |> to_string in
  let side = member "side" json |> to_string |> Common.side_of_string in
  let child_order_type_str = member "child_order_type" json |> to_string in
  let child_order_type =
    match child_order_type_str with
    | "LIMIT" ->
       let price = member "price" json |> to_float in
       Limit price
    | "MARKET" -> Market
    | other -> failwith (!%"order_of_json: '%s'" other)
  in
  let child_order_state = member "child_order_state" json |> to_string in
  let size = member "size" json |> to_float in
  let child_order_date =
    member "child_order_date" json |> to_string |> Datetime.from_string
  in
  {
    id; product_code; side; child_order_type; size; child_order_state;
    child_order_date;
  }

let orders_of_json json =
  let open Json.Util in
  to_list json
  |> List.map order_of_json
