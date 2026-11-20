# READ COMMITTED (افتراضي PostgreSQL)
$ php php/isolation.php
A تقرأ السعر: 45000
B تضبط السعر على 50000 وتثبّت
A تقرؤه مرة أخرى: 50000
A تضيف 1000 إلى السعر: 51000
# REPEATABLE READ
$ php php/isolation.php 'REPEATABLE READ'
A تقرأ السعر: 45000
B تضبط السعر على 50000 وتثبّت
A تقرؤه مرة أخرى: 45000
A تضيف 1000 إلى السعر: ERROR could not serialize access due to concurrent update
