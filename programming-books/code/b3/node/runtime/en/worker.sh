# The same two requests, with the count in a worker thread
$ curl -s 'localhost:3000/primes?limit=5000000' -w ' %{time_total}s\n' & sleep 0.05; curl -s localhost:3000/hello -w ' %{time_total}s\n'; wait
{"message":"Hello from Bit's shop"} 0.001101s
{"limit":5000000,"primes":348513,"ms":1347} 1.348983s
