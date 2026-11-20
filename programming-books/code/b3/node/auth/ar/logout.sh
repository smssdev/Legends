# تسجيل الخروج
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:3000/auth/logout -H "authorization: Bearer $TOKEN"
204
# الرمز نفسه بعدها
$ curl -s localhost:3000/me -H "authorization: Bearer $TOKEN" | jq .title
"لم تسجّل الدخول"
# ما تحفظه قاعدة البيانات
$ psql shop -c 'SELECT email, left(password_hash, 40) AS password_hash FROM users ORDER BY id'
       email       |              password_hash               
-------------------+------------------------------------------
 sara@example.com  | scrypt$32768$mx61uebaH1P3JzfGfds8Wg$IjV7
 omar@example.com  | scrypt$32768$aKYfgynIoDbk2Nnc38yS0w$7cbx
 admin@example.com | scrypt$32768$oo2cMv80w3qIibebwe8YAA$VGAH
 lina@example.com  | scrypt$32768$0Wu1CvHgiDdx5hO2I5z0sA$aIZY
(4 rows)
$ psql shop -c 'SELECT user_id, left(token_hash, 16) AS token_hash, expires_at::date FROM sessions'
 user_id |    token_hash    | expires_at 
---------+------------------+------------
       4 | 4f55c4665f438c32 | 2026-12-20
       2 | d5c25de845e3caf3 | 2026-12-20
       3 | 661085fc2e52a09e | 2026-12-20
(3 rows)
