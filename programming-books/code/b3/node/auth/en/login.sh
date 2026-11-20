# Signing in
$ curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"lina@example.com","password":"a long and silly sentence"}' | jq
{
  "token": "d1Yb2eg4GpvgtBzashBAhPQuFWOR-rAoULstx3_BFmQ",
  "expires_in": 2592000
}
# A wrong password, and an unknown email: the same answer
$ curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"lina@example.com","password":"a wrong sentence"}' | jq
{
  "title": "Email or password is wrong",
  "status": 401,
  "instance": "/auth/login"
}
$ curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"nobody@example.com","password":"a wrong sentence"}' | jq
{
  "title": "Email or password is wrong",
  "status": 401,
  "instance": "/auth/login"
}
