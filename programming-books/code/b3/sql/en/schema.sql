CREATE TABLE customers (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- the database numbers the rows itself; nobody sends an id
  name       text NOT NULL,
  email      text NOT NULL UNIQUE,
  city       text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE products (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL CHECK (price > 0), -- piastres: whole numbers, never fractions
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0) -- the database refuses negative stock, whatever the application does
);

CREATE TABLE orders (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers (id),
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')), -- only these four values can ever be stored
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
  order_id   bigint NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products (id),
  quantity   integer NOT NULL CHECK (quantity BETWEEN 1 AND 99),
  price      integer NOT NULL, -- the price when the order was made: prices change, orders must not
  PRIMARY KEY (order_id, product_id) -- a product appears once per order
);
