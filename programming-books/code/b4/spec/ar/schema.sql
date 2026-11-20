-- يتيح لقيد واحد أن يجمع = (على رقم) و&& (على مدى)
CREATE EXTENSION btree_gist;

CREATE TABLE staff (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL
);
CREATE TABLE services (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  minutes integer NOT NULL CHECK (minutes BETWEEN 5 AND 480),
  -- المال بالقروش، كما في كل كتب السلسلة
  price integer NOT NULL CHECK (price >= 0)
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id bigint NOT NULL REFERENCES staff (id),
  service_id bigint NOT NULL REFERENCES services (id),
  email text NOT NULL,
  -- [البداية, النهاية): النهاية غير داخلة، فلا يتداخل 10:00-10:30 مع 10:30-11:00
  during tstzrange NOT NULL,
  status text NOT NULL DEFAULT 'confirmed'
    CHECK (status IN ('confirmed', 'cancelled')),
  -- US-2: لا يُحجز موظف مرتين في الوقت نفسه أبداً؛ والحجز الملغى يحرر موعده
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (staff_id WITH =, during WITH &&) WHERE (status = 'confirmed')
);

INSERT INTO staff (name) VALUES ('منى'), ('عمر');
INSERT INTO services (name, minutes, price) VALUES ('قص شعر', 30, 25000);
