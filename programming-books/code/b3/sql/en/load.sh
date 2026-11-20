# Create the tables, then fill them
$ psql shop -f schema.sql
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
$ psql shop -q -f seed.sql > /dev/null
$ psql shop -c 'SELECT (SELECT count(*) FROM customers) AS customers, (SELECT count(*) FROM orders) AS orders, (SELECT count(*) FROM order_items) AS items;'
 customers | orders | items  
-----------+--------+--------
      2007 | 100006 | 200009
(1 row)
