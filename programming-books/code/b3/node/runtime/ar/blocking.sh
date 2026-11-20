# طلب بطيء (عدّ على المعالج) وطلب سريع، يُرسلان في اللحظة نفسها
$ curl -s 'localhost:3001/primes?limit=5000000' -w ' %{time_total}s\n' & sleep 0.05; curl -s localhost:3001/hello -w ' %{time_total}s\n'; wait
{"primes":348513} 1.386142s
{"message":"hello"} 1.331990s
