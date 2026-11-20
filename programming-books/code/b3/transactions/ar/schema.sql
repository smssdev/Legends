CREATE TABLE products (
  id    bigint PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL CHECK (price > 0),
  stock integer NOT NULL CHECK (stock >= 0)
);
CREATE TABLE orders (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products (id),
  buyer      integer NOT NULL
);
INSERT INTO products VALUES (1, 'عدة الروبوت', 45000, 1), (2, 'عجلات احتياطية', 6000, 10);
