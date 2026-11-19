# الطلبان نفسهما، والعدّ في خيط عامل
$ curl -s 'localhost:3000/primes?limit=5000000' -w ' %{time_total}s\n' & sleep 0.05; curl -s localhost:3000/hello -w ' %{time_total}s\n'; wait
{"message":"أهلاً من متجر Bit"} 0.001484s
{"limit":5000000,"primes":348513,"ms":1372} 1.373946s
