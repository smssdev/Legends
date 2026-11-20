# Six wrong passwords in a row
$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{http_code} ' localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"sara@example.com","password":"guess number one"}'; done; echo
401 401 401 401 401 429 
$ curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"sara@example.com","password":"guess number seven"}' | jq
{
  "title": "Too many attempts",
  "status": 429,
  "detail": "Try again in 60 seconds.",
  "instance": "/auth/login"
}
