# مزوّد الدفع بطيء: أين ذهب الوقت؟
$ TRACE=$(node browser.ts)
$ node waterfall.ts $TRACE
التتبع 641540bd…  المجموع 1063 ms
click Book                  web      |████████████████████████| 1063 ms
  fetch POST /bookings      web      |████████████████████████| 1063 ms
    POST /bookings          api      | ███████████████████████| 1026 ms
      db SELECT slot        api      | █                      |    6 ms
      call payments         api      | ███████████████████████| 1014 ms
        POST /charges       payments | ███████████████████████| 1011 ms
          fraud check       payments | █                      |   10 ms
          provider checkout payments | ███████████████████████| 1001 ms
      db INSERT booking     api      |                       █|    4 ms
      queue booking.created api      |                       █|    1 ms
