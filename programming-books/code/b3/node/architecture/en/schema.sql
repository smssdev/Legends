CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL, price integer NOT NULL,
  stock integer NOT NULL CHECK (stock >= 0));
CREATE TABLE orders (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, email text NOT NULL,
  total integer NOT NULL, placed_at timestamptz NOT NULL);
CREATE TABLE order_items (order_id bigint NOT NULL REFERENCES orders (id), product_id bigint NOT NULL,
  quantity integer NOT NULL, price integer NOT NULL);
INSERT INTO products VALUES (1, 'Robot kit', 45000, 5), (2, 'Spare wheels', 6000, 50);
