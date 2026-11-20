-- the schema and sample data, loaded the first time the database starts
CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL, price integer NOT NULL);
INSERT INTO products VALUES (1, 'Robot kit', 45000), (2, 'Spare wheels', 6000);
