-- 500,000 products in 2,000 categories of 250 each
CREATE TABLE products (
  id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name     text NOT NULL,
  category text NOT NULL,
  price    integer NOT NULL
);
INSERT INTO products (name, category, price)
SELECT 'Product ' || n,
       (ARRAY['kits', 'wheels', 'cables', 'sensors', 'motors', 'tools', 'lights', 'cases'])[1 + n % 8]
         || '-' || (n % 250),
       (n * 37) % 100000 + 100
FROM generate_series(1, 500000) AS n;
ANALYZE products;
