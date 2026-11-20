# عشرة مشترين، وعدّة روبوت واحدة، وأربع طرق لبيعها
$ php php/race.php naive
naive        1 في المخزون, 10 مبيعات, المخزون الآن 0
$ php php/race.php atomic
atomic       1 في المخزون, 1 مبيعات, المخزون الآن 0
$ php php/race.php lock
lock         1 في المخزون, 1 مبيعات, المخزون الآن 0
$ php php/race.php serializable
serializable 1 في المخزون, 1 مبيعات, المخزون الآن 0, 9 إعادات
