# تسجيل الخروج
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8000/api/auth/logout -H "Accept: application/json" -H "Authorization: Bearer $TOKEN"
204
# الرمز نفسه بعدها
$ curl -s localhost:8000/api/me -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq -c
{"message":"Unauthenticated."}
# ما تحفظه قاعدة البيانات
$ psql shop -c 'SELECT email, left(password, 30) AS password FROM users ORDER BY id'
       email       |            password            
-------------------+--------------------------------
 sara@example.com  | $2y$12$aOEIBSVtHMFtUPMOZ/XDSuP
 omar@example.com  | $2y$12$ub8cx3zHrvkhOh0L5QT/4ul
 admin@example.com | $2y$12$0qNBx/Acy3pLFNv4FQFf9Ok
 lina@example.com  | $2y$12$qaIoc/3zIusG6kB.M7jFEOP
(4 rows)
$ psql shop -c 'SELECT tokenable_id, left(token, 16) AS token, expires_at::date FROM personal_access_tokens ORDER BY id'
 tokenable_id |      token       | expires_at 
--------------+------------------+------------
            4 | 4ace460ad7ae21a5 | 2026-12-20
            2 | 7c1775dbb55ba9a3 | 2026-12-20
            3 | 0a1951e387d55f8a | 2026-12-20
(3 rows)
