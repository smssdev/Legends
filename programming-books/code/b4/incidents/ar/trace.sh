# احجز موعداً، وارسم تتبعه
$ TRACE=$(node browser.ts)
$ node waterfall.ts $TRACE
التتبع 85840b8f…  المجموع 103 ms
click Book                  web      |████████████████████████|  103 ms
  fetch POST /bookings      web      |████████████████████████|  103 ms
    POST /bookings          api      |       ███████████████  |   65 ms
      db SELECT slot        api      |       █                |    6 ms
      call payments         api      |         ████████████   |   53 ms
        POST /charges       payments |         ████████████   |   50 ms
          fraud check       payments |         ██             |   10 ms
          provider checkout payments |            █████████   |   40 ms
      db INSERT booking     api      |                     █  |    4 ms
      queue booking.created api      |                      █ |    1 ms
