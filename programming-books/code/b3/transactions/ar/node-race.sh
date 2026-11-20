# عشرة مشترين، وعدّة روبوت واحدة، وأربع طرق لبيعها
$ node node/race.ts naive
naive        1 في المخزون, 10 مبيعات, المخزون الآن 0
$ node node/race.ts atomic
atomic       1 في المخزون, 1 مبيعات, المخزون الآن 0
$ node node/race.ts lock
lock         1 في المخزون, 1 مبيعات, المخزون الآن 0
$ node node/race.ts serializable
serializable 1 في المخزون, 1 مبيعات, المخزون الآن 0, 9 إعادات
