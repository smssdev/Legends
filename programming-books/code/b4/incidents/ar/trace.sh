# احجز موعداً، وارسم تتبعه
$ TRACE=$(node browser.ts)
$ node waterfall.ts $TRACE
التتبع 990a71cb…  المجموع 116 ms
click Book                  web      |████████████████████████|  116 ms
  fetch POST /bookings      web      |████████████████████████|  116 ms
    POST /bookings          api      |         ██████████████ |   66 ms
      db SELECT slot        api      |         █              |    6 ms
      call payments         api      |          ███████████   |   54 ms
        POST /charges       payments |          ███████████   |   51 ms
          fraud check       payments |          ██            |   10 ms
          provider checkout payments |             ████████   |   40 ms
      db INSERT booking     api      |                     █  |    4 ms
      queue booking.created api      |                      █ |    1 ms
