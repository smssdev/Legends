CREATE EXTENSION btree_gist;
CREATE TABLE staff (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL);
CREATE TABLE services (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL,
  minutes integer NOT NULL CHECK (minutes BETWEEN 5 AND 480), price integer NOT NULL CHECK (price >= 0)
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id bigint NOT NULL REFERENCES staff (id),
  service_id bigint NOT NULL REFERENCES services (id),
  email text NOT NULL,
  during tstzrange NOT NULL,
  status text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')),
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (staff_id WITH =, during WITH &&) WHERE (status = 'confirmed')
);
INSERT INTO staff (name) VALUES ('Mona'), ('Omar');
INSERT INTO services (name, minutes, price) VALUES ('Haircut', 30, 25000);
