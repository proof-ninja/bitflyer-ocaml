let auth = Bitflyer.Auth.from_file ()

let () =
  Bitflyer.buy auth "BTC_JPY" 0.001
