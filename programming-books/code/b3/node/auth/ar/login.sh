# تسجيل الدخول
$ curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"lina@example.com","password":"a long and silly sentence"}' | jq
{
  "token": "C2ffSOp0RUNJixWGBZ_zW4Bg0cxYF1DB1R1X8n9661E",
  "expires_in": 2592000
}
# كلمة مرور خطأ، وبريد مجهول: الجواب نفسه
$ curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"lina@example.com","password":"a wrong sentence"}' | jq
{
  "title": "البريد أو كلمة المرور خطأ",
  "status": 401,
  "instance": "/auth/login"
}
$ curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"nobody@example.com","password":"a wrong sentence"}' | jq
{
  "title": "البريد أو كلمة المرور خطأ",
  "status": 401,
  "instance": "/auth/login"
}
