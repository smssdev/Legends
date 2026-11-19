# طلب طويل يعمل حين يُطلب من الخادم أن يتوقف (Ctrl+C)
$ npm start
> bit-shop@1.0.0 start
> node --env-file=.env src/server.ts

info  يستمع على http://localhost:3000
^C
info  SIGINT: لا اتصالات جديدة، وننهي الطلبات الجارية
info  GET /primes?limit=5000000 200 1309ms
info  انتهت كل الطلبات، إلى اللقاء
