# NULL is not a value: = NULL is never true
shop=# SELECT name, city FROM customers WHERE city = NULL;
 name | city 
------+------
(0 rows)
shop=# SELECT name, city FROM customers WHERE city IS NULL;
 name  | city 
-------+------
 Karim | 
(1 row)
shop=# SELECT NULL = NULL AS equal, NULL IS NULL AS is_null, 1 + NULL AS sum;
 equal | is_null | sum 
-------+---------+-----
       | t       |    
(1 row)
