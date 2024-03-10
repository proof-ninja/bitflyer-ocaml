let getbalance auth =
  let path = "/v1/me/getbalance" in
  ApiCommon.get auth path []
