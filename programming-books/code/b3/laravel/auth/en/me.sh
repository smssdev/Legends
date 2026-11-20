# Without a token
$ curl -s localhost:8000/api/me -H 'Accept: application/json' | jq
{
  "message": "Unauthenticated."
}
# With the token
$ TOKEN=$(curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"lina@example.com","password":"a long and silly sentence"}' | jq -r .token)
$ curl -s localhost:8000/api/me -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq
{
  "id": 4,
  "email": "lina@example.com",
  "name": "Lina",
  "role": "customer"
}
