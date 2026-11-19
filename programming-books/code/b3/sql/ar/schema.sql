CREATE TABLE customers (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- تُرقّم قاعدة البيانات الصفوف بنفسها، ولا أحد يرسل رقماً
  name       text NOT NULL,
  email      text NOT NULL UNIQUE,
  city       text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE products (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL CHECK (price > 0), -- بالقروش: أعداد صحيحة، لا كسور أبداً
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0) -- ترفض قاعدة البيانات المخزون السالب، مهما فعل التطبيق
);

CREATE TABLE orders (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers (id),
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')), -- لا يمكن أن تُخزَّن إلا هذه القيم الأربع
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
  order_id   bigint NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products (id),
  quantity   integer NOT NULL CHECK (quantity BETWEEN 1 AND 99),
  price      integer NOT NULL, -- السعر عند الطلب: الأسعار تتغير، والطلبات يجب ألا تتغير
  PRIMARY KEY (order_id, product_id) -- يظهر المنتج مرة واحدة في كل طلب
);
