let getbalance = Assets.getbalance
let sendchildorder = Trade.sendchildorder
let getchildorders = Trade.getchildorders
let getexecutions = Trade.getexecutions
let sendparentorder = Trade.sendparentorder
let getparentorders = Trade.getparentorders
let getparentorder = Trade.getparentorder
let cancelchildorder = Trade.cancelchildorder
let cancelparentorder = Trade.cancelparentorder
let cancelallchildorders = Trade.cancelallchildorders
let getpositions = Trade.getpositions
let gettradingcommission = Trade.gettradingcommission
let getaddresses = Account_statement.getaddresses
let getcollateral = Assets.getcollateral
let getcollateralaccount = Assets.getcollateralaccount
let getcoinins = Account_statement.getcoinins
let getcoinouts = Account_statement.getcoinouts
let getbankaccounts = Account_statement.getbankaccounts
let getdeposits = Account_statement.getdeposits
let withdraw = Account_statement.withdraw
let getwithdrawals = Account_statement.getwithdrawals
let getbalancehistory = Trade.getbalancehistory
let getcollateralhistory = Trade.getcollateralhistory

(* このAPIキーで呼出可能なHTTP Private APIのpathの一覧を取得する *)
let getpermissions auth =
  let path = "/v1/me/getpermissions" in
  ApiCommon.get auth path []
  |> Lwt.map (fun json ->
      Common.Json.Util.to_list json |> List.map Common.Json.Util.to_string)
