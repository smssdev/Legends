# The non-functional requirements, as numbers
$ node budget.ts
target    downtime
99%       432.0 min/month
99.5%     216.0 min/month
99.9%     43.2 min/month
99.95%    21.6 min/month
99.99%    4.3 min/month

1,800,000 requests a day
20.8 average per second
83.3 peak per second (x4)

18,250,000 bookings a year
3.4 GB table size a year
