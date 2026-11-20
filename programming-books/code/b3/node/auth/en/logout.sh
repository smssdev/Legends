# Signing out
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:3000/auth/logout -H "authorization: Bearer $TOKEN"
204
# The same token afterwards
$ curl -s localhost:3000/me -H "authorization: Bearer $TOKEN" | jq .title
"Not signed in"
# What the database keeps
$ psql shop -c 'SELECT email, left(password_hash, 40) AS password_hash FROM users ORDER BY id'
       email       |              password_hash               
-------------------+------------------------------------------
 sara@example.com  | scrypt$32768$Bhn1h7EoWOGZ7lU5t1g6Eg$Kgh3
 omar@example.com  | scrypt$32768$WsBZfR6lWttaUYGzPfXEAQ$ZVpu
 admin@example.com | scrypt$32768$8Nt9qiHM-EjSITep5Xm69A$vSvz
 lina@example.com  | scrypt$32768$MmmRiCEaSxwtwDPDT_woAA$gh1_
(4 rows)
$ psql shop -c 'SELECT user_id, left(token_hash, 16) AS token_hash, expires_at::date FROM sessions'
 user_id |    token_hash    | expires_at 
---------+------------------+------------
       4 | 6c598c6d78a38d53 | 2026-12-20
       2 | 22aad72542c31eee | 2026-12-20
       3 | 0db92fa024403f65 | 2026-12-20
(3 rows)
