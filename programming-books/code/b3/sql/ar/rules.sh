# تفرض قاعدة البيانات قواعدها مع كل كتابة
shop=# INSERT INTO products (name, price) VALUES ('Free sample', 0);
ERROR:  new row for relation "products" violates check constraint "products_price_check"
DETAIL:  Failing row contains (13, Free sample, 0, 0).
shop=# INSERT INTO orders (customer_id) VALUES (999999);
ERROR:  insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
DETAIL:  Key (customer_id)=(999999) is not present in table "customers".
shop=# INSERT INTO customers (name, email) VALUES ('Sara 2', 'sara@example.com');
ERROR:  duplicate key value violates unique constraint "customers_email_key"
DETAIL:  Key (email)=(sara@example.com) already exists.
shop=# UPDATE products SET stock = stock - 5 WHERE id = 3;
ERROR:  new row for relation "products" violates check constraint "products_stock_check"
DETAIL:  Failing row contains (3, حزمة بطارية, 12500, -5).
