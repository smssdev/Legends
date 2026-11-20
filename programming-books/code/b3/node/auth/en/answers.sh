# Signed in on two devices, then out of both
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:3000/auth/logout-all -H "authorization: Bearer $PHONE"
204
$ curl -s -o /dev/null -w "%{http_code}\n" localhost:3000/me -H "authorization: Bearer $LAPTOP"
401
