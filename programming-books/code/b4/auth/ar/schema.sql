CREATE EXTENSION btree_gist;
CREATE TABLE businesses (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL);
CREATE TABLE users (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses (id),
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  role text NOT NULL CHECK (role IN ('owner', 'staff'))
);
CREATE TABLE sessions (
  token_hash text PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL
);
CREATE TABLE staff (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses (id),
  name text NOT NULL
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id bigint NOT NULL REFERENCES staff (id),
  email text NOT NULL,
  during tstzrange NOT NULL,
  status text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')),
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (staff_id WITH =, during WITH &&) WHERE (status = 'confirmed')
);
INSERT INTO businesses (name) VALUES ('صالون بِت'), ('عيادة نور');
INSERT INTO staff (business_id, name) VALUES (1, 'منى'), (1, 'عمر'), (2, 'د. هناء');
INSERT INTO bookings (staff_id, email, during) VALUES
  (1, 'sara@example.com', '[2026-12-01 10:00+02, 2026-12-01 10:30+02)'),
  (3, 'ali@example.com', '[2026-12-01 11:00+02, 2026-12-01 11:30+02)'),
  (2, 'nour@example.com', '[2026-12-01 10:30+02, 2026-12-01 11:00+02)');
