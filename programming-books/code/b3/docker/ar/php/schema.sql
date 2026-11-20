-- المخطط والبيانات النموذجية، تُحمَّل أول مرة تبدأ فيها قاعدة البيانات
CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL, price integer NOT NULL);
INSERT INTO products VALUES (1, 'عدة الروبوت', 45000), (2, 'عجلات احتياطية', 6000);
