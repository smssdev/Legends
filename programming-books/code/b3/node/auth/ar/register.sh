# التسجيل
$ curl -s -i localhost:3000/auth/register -H 'content-type: application/json' -d '{"email":"Lina@Example.com","name":"لينا","password":"a long and silly sentence"}'
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8

{"id":4,"email":"lina@example.com","name":"لينا","role":"customer"}
# البريد نفسه مرة أخرى
$ curl -s localhost:3000/auth/register -H 'content-type: application/json' -d '{"email":"lina@example.com","name":"لينا","password":"another long sentence"}' | jq
{
  "title": "البريد مسجّل من قبل",
  "status": 409,
  "instance": "/auth/register"
}
# كلمة مرور أقصر من اللازم
$ curl -s localhost:3000/auth/register -H 'content-type: application/json' -d '{"email":"sam@example.com","name":"Sam","password":"short"}' | jq
{
  "title": "جسم غير صالح",
  "status": 422,
  "instance": "/auth/register",
  "errors": [
    {
      "field": "password",
      "message": "Too small: expected string to have >=12 characters"
    }
  ]
}
