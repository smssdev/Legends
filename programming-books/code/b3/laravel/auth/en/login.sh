# Signing in
$ curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"lina@example.com","password":"a long and silly sentence"}' | jq
{
  "token": "1|qu8uqJFpMFyaijcVN9DQPlDNWEY5m9CVZfUeSxh17fda9374",
  "expires_in": 2592000
}
# A wrong password, and an unknown email: the same answer
$ curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"lina@example.com","password":"a wrong sentence"}' | jq
{
  "message": "Email or password is wrong."
}
$ curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"nobody@example.com","password":"a wrong sentence"}' | jq
{
  "message": "Email or password is wrong."
}
