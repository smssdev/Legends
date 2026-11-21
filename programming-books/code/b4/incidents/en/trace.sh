# Book a slot, and draw its trace
$ TRACE=$(node browser.ts)
$ node waterfall.ts $TRACE
trace e257ee16…  total 105 ms
click Book                  web      |████████████████████████|  105 ms
  fetch POST /bookings      web      |████████████████████████|  105 ms
    POST /bookings          api      |        ███████████████ |   66 ms
      db SELECT slot        api      |        █               |    6 ms
      call payments         api      |         ████████████   |   54 ms
        POST /charges       payments |         ████████████   |   51 ms
          fraud check       payments |         ██             |   10 ms
          provider checkout payments |            █████████   |   40 ms
      db INSERT booking     api      |                     █  |    4 ms
      queue booking.created api      |                      █ |    1 ms
