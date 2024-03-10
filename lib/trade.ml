open Common

let make_param product_code order side size : Yojson.Basic.t =
  match order with
  | Limit price ->
     `Assoc [
         ("product_code", `String product_code);
         ("child_order_type", `String "LIMIT");
         ("price", `String (string_of_int price));
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
  let timestamp = Datetime.now () in
  let path = "/v1/me/sendchildorder" in
  let data = make_param product_code order side size
             |> Yojson.Basic.to_string
  in
  let headers = Auth.make_header auth timestamp "POST" path data in
  Http.post ~headers Common.host path data
