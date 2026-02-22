open Lwt
open Common

let sendchildorder auth product_code order side size =
  let path = "/v1/me/sendchildorder" in
  let data = Child_order.json_of_order product_code order side size
             |> Json.to_string
  in
  ApiCommon.post auth path data

(**
   ## Query Parameters
   > * [product_code]: Please specify a product_code, as obtained from the Market List. Please refer to the Regions to check available products in each region.
   > * count, before, after: See Pagination. If either before or after is specified, ["ACTIVE"] orders will not be included in the result.
   > * child_order_state: When specified, return only orders that match the specified value. If not specified, returns a concatenated list of ["ACTIVE"] and non-ACTIVE orders.
   > You can specify one of the following:
      > ** ["ACTIVE"]: Return open orders
      > ** ["COMPLETED"]: Return fully completed orders
      > ** ["CANCELED"]: Return orders that have been cancelled by the customer
      > ** ["EXPIRED"]: Return order that have been cancelled due to expiry
      > ** ["REJECTED"]: Return failed orders
   > * [child_order_id], [child_order_acceptance_id]: ID for the child order.
   > * [parent_order_id]: If specified, a list of all orders associated with the parent order is obtained.

   ## Pagenation
   see: https://lightning.bitflyer.com/docs?lang=en#pagination
   > * count: Specifies the number of results. If this is omitted, the value will be 100.
   > * before: Obtains data having an id lower than the value specified for this parameter.
                                                                            > * after: Obtains data having an id higher than the value specified for this parameter.
 *)
let getchildorders auth ?child_order_state ?count ?before ?after product_code =
  let path = "/v1/me/getchildorders" in
  let query =
    [("product_code", product_code)]
    |> list_add_opt
         (Option.map (fun s -> ("child_order_state", s)) child_order_state)
    |> list_add_opt (Option.map (fun c -> ("count", !%"%d" c)) count)
    |> list_add_opt (Option.map (fun x -> ("before", !%"%d" x)) before)
    |> list_add_opt (Option.map (fun x -> ("after", !%"%d" x)) after)
  in
  ApiCommon.get auth path query >>= fun json ->
  Child_order.orders_of_json json
  |> fun orders -> Lwt.return (json, orders)
  (*
  let headers = Auth.make_header auth "GET" path "" in
  Http.get ~headers Common.host path query
*)


type execution = {
    id : int;
    child_order_id: string;  (* "JOR20150707-060559-021935", *)
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
  let child_order_id = member "child_order_id" json |> to_string in
  let side = member "side" json |> to_string |> Common.side_of_string in
  let price = member "price" json |> to_float in
  let size = member "size" json |> to_float in
  let exec_date = member "exec_date" json |> to_string in
  {
    id; child_order_id; side; price; size; exec_date
  }

let executions_of_json json =
  let open Json.Util in
  to_list json
  |> List.map execution_of_json

(**
   ## Query Parameters
   see: https://lightning.bitflyer.com/docs?lang=en#list-executions

   > * [product_code]: Please specify a product_code, as obtained from the Market List. Please refer to the Regions to check available products in each region.
   > * [count], [before], [after]: See Pagination. (Same as [Trade.getchildorders])
   > * [child_order_id]: Optional. When specified, a list of stipulations related to the order will be displayed.
   > * [child_order_acceptance_id]: Optional. Expects an ID from Send a New Order. When specified, a list of stipulations related to the corresponding order will be displayed.
 *)
let getexecutions auth ?count ?before ? after product_code =
  let path = "/v1/me/getexecutions" in
  let query =
    [("product_code", product_code)]
    |> list_add_opt (Option.map (fun c -> ("count", !%"%d" c)) count)
    |> list_add_opt (Option.map (fun x -> ("before", !%"%d" x)) before)
    |> list_add_opt (Option.map (fun x -> ("after", !%"%d" x)) after)
  in
  ApiCommon.get auth path query >>= fun json ->
  Lwt.return (executions_of_json json)

let sendparentorder auth special_order =
  let path = "/v1/me/sendparentorder" in
  let data = Parent_order.json_of_order special_order
             |> Json.to_string
  in
  ApiCommon.post auth path data

let gettradingcommision auth product_code =
  let path = "/v1/me/gettradingcommision" in
  let query = [("product_code", product_code)] in
  ApiCommon.get auth path query >>= fun json ->
  let open Json.Util in
  let commision_rate = json |> member "commision_rate" |> to_float in
  Lwt.return commision_rate

let getparentorders auth product_code =
  let path = "/v1/me/getparentorders" in
  let query = [("product_code", product_code)] in
  ApiCommon.get auth path query >>= fun json ->
  Json.Util.to_list json
  |> List.map Parent_order.order_of_json
  |> fun orders -> Lwt.return (json, orders)


let getparentorder auth parent_order_id =
  let path = "/v1/me/getparentorder" in
  let query = [("parent_order_id", parent_order_id)] in
  ApiCommon.get auth path query >>= fun json ->
  Lwt.return json
