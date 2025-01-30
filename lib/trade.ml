open Lwt
open Common

let sendchildorder auth product_code order side size =
  let path = "/v1/me/sendchildorder" in
  let data = Child_order.json_of_order product_code order side size
             |> Json.to_string
  in
  ApiCommon.post auth path data

let getchildorders auth product_code =
  let path = "/v1/me/getchildorders" in
  let query = [("product_code", product_code)] in
  ApiCommon.get auth path query >>= fun json ->
  Child_order.orders_of_json json
  |> fun orders -> Lwt.return (json, orders)
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
  Lwt.return json

let getparentorder auth parent_order_id =
  let path = "/v1/me/getparentorder" in
  let query = [("parent_order_id", parent_order_id)] in
  ApiCommon.get auth path query >>= fun json ->
  Lwt.return json
