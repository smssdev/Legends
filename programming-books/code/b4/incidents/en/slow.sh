# The payment provider is slow: where did the time go?
$ TRACE=$(node browser.ts)
$ node waterfall.ts $TRACE
trace d5a78003…  total 1057 ms
click Book                  web      |████████████████████████| 1057 ms
  fetch POST /bookings      web      |████████████████████████| 1057 ms
    POST /bookings          api      | ███████████████████████| 1025 ms
      db SELECT slot        api      | █                      |    6 ms
      call payments         api      | ███████████████████████| 1013 ms
        POST /charges       payments | ███████████████████████| 1010 ms
          fraud check       payments | █                      |   10 ms
          provider checkout payments | ███████████████████████| 1000 ms
      db INSERT booking     api      |                       █|    4 ms
      queue booking.created api      |                       █|    1 ms
