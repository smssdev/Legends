# التسجيل
$ curl -s -i localhost:8000/api/auth/register -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"Lina@Example.com","name":"لينا","password":"a long and silly sentence"}'
HTTP/1.1 201 Created
Content-Type: application/json
{"id":4,"email":"lina@example.com","name":"\u0644\u064a\u0646\u0627","role":"customer"}
# البريد نفسه مرة أخرى
$ curl -s localhost:8000/api/auth/register -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"lina@example.com","name":"لينا","password":"another long sentence"}' | jq
{
  "message": "The email has already been taken.",
  "errors": {
    "email": [
      "The email has already been taken."
    ]
  }
}
# كلمة مرور أقصر من اللازم
$ curl -s localhost:8000/api/auth/register -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"sam@example.com","name":"Sam","password":"short"}' | jq
{
  "message": "The password field must be at least 12 characters.",
  "errors": {
    "password": [
      "The password field must be at least 12 characters."
    ]
  }
}
