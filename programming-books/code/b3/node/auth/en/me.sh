# Without a token
$ curl -s localhost:3000/me | jq
{
  "title": "Not signed in",
  "status": 401,
  "detail": "Send a valid token: Authorization: Bearer <token>.",
  "instance": "/me"
}
# With the token
$ TOKEN=$(curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"lina@example.com","password":"a long and silly sentence"}' | jq -r .token)
$ curl -s localhost:3000/me -H "authorization: Bearer $TOKEN" | jq
{
  "id": 4,
  "email": "lina@example.com",
  "name": "Lina",
  "role": "customer"
}
