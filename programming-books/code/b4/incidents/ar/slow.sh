# مزوّد الدفع بطيء: أين ذهب الوقت؟
$ TRACE=$(node browser.ts)
$ node waterfall.ts $TRACE
التتبع f813c0a6…  المجموع 1072 ms
click Book                  web      |████████████████████████| 1072 ms
  fetch POST /bookings      web      |████████████████████████| 1072 ms
    POST /bookings          api      | ███████████████████████| 1027 ms
      db SELECT slot        api      | █                      |    6 ms
      call payments         api      | ███████████████████████| 1015 ms
        POST /charges       payments | ███████████████████████| 1011 ms
          fraud check       payments | █                      |   10 ms
          provider checkout payments | ██████████████████████ | 1001 ms
      db INSERT booking     api      |                       █|    5 ms
      queue booking.created api      |                       █|    1 ms
