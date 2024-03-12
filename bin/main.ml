open Bitflyer

let auth = Auth.auth ()

let () =
  Log.set_log_level Log.DEBUG;
  Bitflyer.buy auth "BTC_JPY" 0.001
