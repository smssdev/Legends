# Signing out
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8000/api/auth/logout -H "Accept: application/json" -H "Authorization: Bearer $TOKEN"
204
# The same token afterwards
$ curl -s localhost:8000/api/me -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq -c
{"message":"Unauthenticated."}
# What the database keeps
$ psql shop -c 'SELECT email, left(password, 30) AS password FROM users ORDER BY id'
       email       |            password            
-------------------+--------------------------------
 sara@example.com  | $2y$12$9BUYGLMcP5MGpupHHcSnPet
 omar@example.com  | $2y$12$OthbF7Ayc6VNkewfPzqMUuY
 admin@example.com | $2y$12$pAjBoRKoK36q.HFHJ.OYIuc
 lina@example.com  | $2y$12$4KwbgjD/tx4rV.GQI5ltWOd
(4 rows)
$ psql shop -c 'SELECT tokenable_id, left(token, 16) AS token, expires_at::date FROM personal_access_tokens ORDER BY id'
 tokenable_id |      token       | expires_at 
--------------+------------------+------------
            4 | 2e0b2817c318eb72 | 2026-12-20
            2 | 17b9a12004f16328 | 2026-12-20
            3 | 36b1a9a075866e9e | 2026-12-20
(3 rows)
