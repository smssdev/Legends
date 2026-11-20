# The address is fixed; retry the failed job
$ node demos/retry.ts
order-1004 retried
$ node src/worker.ts --until-empty
 0.0s sending the confirmation for order 1004 (attempt 2)
 0.3s order-1004 sent
