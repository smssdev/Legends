# The cost of a feed
$ node fanout.ts
strategy                  writes per post    reads per feed view
ordinary account (300 followers)
  fan-out on write                    300                      1
  fan-out on read                       1                    200
popular account (2,000,000 followers)
  fan-out on write              2,000,000                      1
  fan-out on read                       1                    200
