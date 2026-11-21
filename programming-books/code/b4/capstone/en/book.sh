# Salon A books, until the free plan's limit
$ ./book key_a 10:00
{"id":"5"}
$ ./book key_a 10:15
{"message":"That time was just taken. Please choose another."}
$ ./book key_a 11:00
{"id":"7"}
$ ./book key_a 12:00
{"message":"Free plan: 5 bookings a month. Upgrade to Pro for more."}
