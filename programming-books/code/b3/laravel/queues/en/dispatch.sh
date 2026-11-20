# The shop dispatches four confirmations (and one twice)
$ php artisan shop:dispatch
order 1001: queued in 20.9 ms
order 1002: queued in 1.1 ms
order 1003: queued in 0.6 ms
order 1004: queued in 0.7 ms
order 1001: queued in 0.4 ms
# Nobody is working yet: the jobs wait in Redis
$ php artisan queue:monitor redis:default --no-ansi

  Queue name ................................................... Size / Status  
  [redis] default ..................................................... [4] OK  
  Pending jobs ............................................................. 4  
  Delayed jobs ............................................................. 0  
  Reserved jobs ............................................................ 0  
  Oldest pending job ........................................... 0 seconds ago  
