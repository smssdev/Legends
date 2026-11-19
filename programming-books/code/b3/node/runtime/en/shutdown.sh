# A long request is running when the server is told to stop (Ctrl+C)
$ npm start
> bit-shop@1.0.0 start
> node --env-file=.env src/server.ts

info  Listening on http://localhost:3000
^C
info  SIGINT: no new connections, finishing requests in progress
info  GET /primes?limit=5000000 200 1375ms
info  all requests finished, bye
