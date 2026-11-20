CREATE TABLE products (
  id    bigint PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL CHECK (price > 0)
);
INSERT INTO products VALUES (1, 'Robot kit', 45000), (2, 'Spare wheels', 6000);
