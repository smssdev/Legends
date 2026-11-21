# The rules that must never break, tested on the real database
$ node --test app.test.ts
✔ a salon never sees another salon's bookings (22.762482ms)
✔ without a salon, a query returns nothing (0.85868ms)
✔ the plan limit holds under concurrent bookings (34.800283ms)
✔ a webhook delivered twice is applied once (4.598347ms)
ℹ tests 4
ℹ pass 4
ℹ fail 0
