# Omar signs in
$ OMAR=$(curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"omar@example.com","password":"omar-password-2026"}' | jq -r .token)
# His own orders
$ curl -s localhost:3000/orders -H "authorization: Bearer $OMAR" | jq -c
[{"id":3,"total":12000}]
# Sara's order
$ curl -s localhost:3000/orders/1 -H "authorization: Bearer $OMAR" | jq
{
  "title": "Not found",
  "status": 404,
  "detail": "There is no order 1.",
  "instance": "/orders/1"
}
# The admin list, as Omar
$ curl -s localhost:3000/admin/users -H "authorization: Bearer $OMAR" | jq
{
  "title": "Not allowed",
  "status": 403,
  "detail": "This needs the admin role.",
  "instance": "/admin/users"
}
# The admin list, as an admin
$ ADMIN=$(curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"admin@example.com","password":"admin-password-2026"}' | jq -r .token)
$ curl -s localhost:3000/admin/users -H "authorization: Bearer $ADMIN" | jq -c ".[]"
{"id":1,"email":"sara@example.com","role":"customer"}
{"id":2,"email":"omar@example.com","role":"customer"}
{"id":3,"email":"admin@example.com","role":"admin"}
{"id":4,"email":"lina@example.com","role":"customer"}
