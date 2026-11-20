# رسائل مرقّمة لكل محادثة
$ psql shop -q -c 'INSERT INTO conversations DEFAULT VALUES; INSERT INTO conversations DEFAULT VALUES'
$ psql shop -At -c "SELECT send(1, 'Hi, is 10:30 free?'), send(2, 'Hello'), send(1, 'Yes, booked for you'), send(1, 'Thanks!')"
1|1|2|3
$ psql shop -c 'SELECT conversation_id, seq, body FROM messages ORDER BY conversation_id, seq'
 conversation_id | seq |        body         
-----------------+-----+---------------------
               1 |   1 | Hi, is 10:30 free?
               1 |   2 | Yes, booked for you
               1 |   3 | Thanks!
               2 |   1 | Hello
(4 rows)
