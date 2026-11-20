# عمر يسجّل الدخول
$ OMAR=$(curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"omar@example.com","password":"omar-password-2026"}' | jq -r .token)
# طلباته هو
$ curl -s localhost:8000/api/orders -H "Accept: application/json" -H "Authorization: Bearer $OMAR" | jq -c
[{"id":3,"total":12000}]
# طلب سارة
$ curl -s localhost:8000/api/orders/1 -H "Accept: application/json" -H "Authorization: Bearer $OMAR" | jq
{
  "message": "Not Found"
}
# قائمة المدير، بصفة عمر
$ curl -s localhost:8000/api/admin/users -H "Accept: application/json" -H "Authorization: Bearer $OMAR" | jq
{
  "message": "This action is unauthorized."
}
# قائمة المدير، بصفة مدير
$ ADMIN=$(curl -s localhost:8000/api/auth/login -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"admin@example.com","password":"admin-password-2026"}' | jq -r .token)
$ curl -s localhost:8000/api/admin/users -H "Accept: application/json" -H "Authorization: Bearer $ADMIN" | jq -c '.[]'
{"id":1,"email":"sara@example.com","role":"customer"}
{"id":2,"email":"omar@example.com","role":"customer"}
{"id":3,"email":"admin@example.com","role":"admin"}
{"id":4,"email":"lina@example.com","role":"customer"}
