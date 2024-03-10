open Lwt
open Common

let make_param product_code order side size : Json.t =
  match order with
  | Limit price ->
     `Assoc [
         ("product_code", `String product_code);
         ("child_order_type", `String "LIMIT");
         ("price", `String (string_of_float price));
         ("side", `String side);
         ("size", `String (string_of_float size));
       ]
  | Market ->
     `Assoc [
         ("product_code", `String product_code);
         ("child_order_type", `String "MARKET");
         ("side", `String side);
         ("size", `String (string_of_float size));
       ]

let sendchildorder auth product_code order side size =
  let path = "/v1/me/sendchildorder" in
  let data = make_param product_code order side size
             |> Json.to_string
  in
  ApiCommon.post auth path data

type order = {
    id: int;
    (*"child_order_id": "JOR20150707-084555-022523",*)
    product_code: string;
    side: side;
    child_order_type: order_type;
    (*"average_price": 30000,*)
    size: float;
    (*TODO"child_order_state": "COMPLETED",*)
    (*"expire_date": "2015-07-14T07:25:52",*)
    (*"child_order_date": "2015-07-07T08:45:53",*)
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
  let size = member "size" json |> to_float in
  {
    id; product_code; side; child_order_type; size
  }

let orders_of_json json =
  let open Json.Util in
  to_list json
  |> List.map order_of_json

let getchildorders auth product_code =
  let path = "/v1/me/getchildorders" in
  let query = [("product_code", product_code)] in
  ApiCommon.get auth path query >>= fun json ->
  orders_of_json json
  |> Lwt.return
  (*
  let headers = Auth.make_header auth "GET" path "" in
  Http.get ~headers Common.host path query
*)


type execution = {
    id : int;
    (* "child_order_id": "JOR20150707-060559-021935", *)
    side: side;
    price: float;
    size: float;
    (* "commission": 0, *)
    exec_date: string; (* "2015-07-07T09:57:40.397", *)
    (* "child_order_acceptance_id": "JRF20150707-060559-396699" *)
}

let execution_of_json json =
  let open Json.Util in
  let id = member "id" json |> to_int in
  let side = member "side" json |> to_string |> Common.side_of_string in
  let price = member "price" json |> to_float in
  let size = member "size" json |> to_float in
  let exec_date = member "exec_date" json |> to_string in
  {
    id; side; price; size; exec_date
  }

let executions_of_json json =
  let open Json.Util in
  to_list json
  |> List.map execution_of_json

let getexecutions auth product_code =
  let path = "/v1/me/getexecutions" in
  let query = [("product_code", product_code)] in
  ApiCommon.get auth path query >>= fun json ->
  Lwt.return (executions_of_json json)
