# بلا رمز
$ curl -s localhost:3000/me | jq
{
  "title": "لم تسجّل الدخول",
  "status": 401,
  "detail": "أرسل رمزاً صالحاً: Authorization: Bearer <token>.",
  "instance": "/me"
}
# بالرمز
$ TOKEN=$(curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"lina@example.com","password":"a long and silly sentence"}' | jq -r .token)
$ curl -s localhost:3000/me -H "authorization: Bearer $TOKEN" | jq
{
  "id": 4,
  "email": "lina@example.com",
  "name": "لينا",
  "role": "customer"
}
