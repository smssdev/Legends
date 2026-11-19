# NULL ليست قيمة: = NULL لا تصدق أبداً
shop=# SELECT name, city FROM customers WHERE city = NULL;
 name | city 
------+------
(0 rows)
shop=# SELECT name, city FROM customers WHERE city IS NULL;
 name | city 
------+------
 كريم | 
(1 row)
shop=# SELECT NULL = NULL AS equal, NULL IS NULL AS is_null, 1 + NULL AS sum;
 equal | is_null | sum 
-------+---------+-----
       | t       |    
(1 row)
