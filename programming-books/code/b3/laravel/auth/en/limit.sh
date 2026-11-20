# Six wrong passwords in a row
$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code} " localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"sara@example.com","password":"guess number one"}'; done; echo
401 401 401 401 401 429 
$ curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"sara@example.com","password":"guess number seven"}' | jq
{
  "message": "Too many attempts. Try again in 59 seconds."
}
