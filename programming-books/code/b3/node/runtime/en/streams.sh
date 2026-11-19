# A million orders, about 24 MB
$ node demos/make-orders.ts
1000000 orders written to orders.csv
$ ls -lh orders.csv | awk '{print $5, $9}'
24M orders.csv
# Read the whole file, then add up
$ node demos/total-read.ts
total: 49999500000, peak memory: 204 MB
# Read it as a stream, line by line
$ node demos/total-stream.ts
total: 49999500000, peak memory: 84 MB
