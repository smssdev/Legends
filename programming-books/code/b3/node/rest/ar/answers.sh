$ node answers/search-demo.ts
200 ["حزمة بطارية"]
400 [{"field":"querystring.q","message":"Too small: expected string to have >=2 characters"}]
$ node --test --test-reporter=spec answers/idempotency.test.ts 2>&1 | grep -E '✔|✖'
✔ keys belong to one client (2.385739ms)
✔ keys expire after the time to live (0.254725ms)
