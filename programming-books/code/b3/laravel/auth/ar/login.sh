# تسجيل الدخول
$ curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"lina@example.com","password":"a long and silly sentence"}' | jq
{
  "token": "1|xvSLaOMIUHVAe4pmlTO2HXkbzmGKxsHWkiPUk4pT4c69f76d",
  "expires_in": 2592000
}
# كلمة مرور خطأ، وبريد مجهول: الجواب نفسه
$ curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"lina@example.com","password":"a wrong sentence"}' | jq
{
  "message": "البريد أو كلمة المرور خطأ."
}
$ curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"nobody@example.com","password":"a wrong sentence"}' | jq
{
  "message": "البريد أو كلمة المرور خطأ."
}
