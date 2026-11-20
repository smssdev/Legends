# What a customer sees while the breaker is open
$ node customer.ts | sed -n '1,4p'
1 {"error":"Deposits are unavailable right now; your time is held for 30 minutes.","cause":"HTTP 503"}
2 {"error":"Deposits are unavailable right now; your time is held for 30 minutes.","cause":"HTTP 503"}
3 {"error":"Deposits are unavailable right now; your time is held for 30 minutes.","cause":"circuit open"}
4 {"error":"Deposits are unavailable right now; your time is held for 30 minutes.","cause":"circuit open"}
