# كتابات تجيب: RETURNING، والإدراج أو التحديث بـ ON CONFLICT
shop=# INSERT INTO customers (name, email, city)
shop-# VALUES ('Nour', 'nour@example.com', 'Giza')
shop-# RETURNING id, created_at;
  id  |          created_at           
------+-------------------------------
 2009 | 2026-11-19 20:42:40.095471+00
(1 row)

INSERT 0 1
shop=# INSERT INTO customers (name, email, city)
shop-# VALUES ('Nour', 'nour@example.com', 'Aswan')
shop-# ON CONFLICT (email) DO UPDATE SET city = excluded.city
shop-# RETURNING id, name, city;
  id  | name | city  
------+------+-------
 2009 | Nour | Aswan
(1 row)

INSERT 0 1
shop=# UPDATE products SET stock = stock + 5
shop-# WHERE id = 3
shop-# RETURNING name, stock;
    name     | stock 
-------------+-------
 حزمة بطارية |     5
(1 row)

UPDATE 1
