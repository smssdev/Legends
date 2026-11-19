# One slow request (a CPU count) and one quick one, sent at the same moment
$ curl -s 'localhost:3001/primes?limit=5000000' -w ' %{time_total}s\n' & sleep 0.05; curl -s localhost:3001/hello -w ' %{time_total}s\n'; wait
{"primes":348513} 1.394915s
{"message":"hello"} 1.343057s
