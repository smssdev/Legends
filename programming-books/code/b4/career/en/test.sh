# Both versions, against the tricky cases
$ node --test slots.test.ts
✔ an empty day is one gap (1.327793ms)
✔ overlapping bookings (0.314619ms)
✔ bookings that touch leave no gap (0.155603ms)
✔ unsorted input (0.363691ms)
✔ a full day has no gaps (0.230855ms)
✔ both agree on 200 random days (8.020813ms)
ℹ tests 6
ℹ pass 6
ℹ fail 0
