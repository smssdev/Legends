# Terminal 2: the request still gets its answer
$ curl -s 'localhost:3000/primes?limit=5000000' -w ' %{http_code}\n'
{"limit":5000000,"primes":348513,"ms":1375} 200
