# A worker starts and does them
$ node src/worker.ts --until-empty
 0.0s sending the confirmation for order 1001 (attempt 1)
 0.0s sending the confirmation for order 1002 (attempt 1)
 0.3s order-1001 sent
 0.3s sending the confirmation for order 1003 (attempt 1)
 0.3s order-1002 sent
 0.3s sending the confirmation for order 1004 (attempt 1)
 0.6s order-1003 failed: mail service unavailable
 0.6s order-1004 failed: invalid address: karim-at-example.com
 0.6s order-1004 gave up; attempts made: 1
 1.7s sending the confirmation for order 1003 (attempt 2)
 2.0s order-1003 failed: mail service unavailable
 4.0s sending the confirmation for order 1003 (attempt 3)
 4.3s order-1003 sent
