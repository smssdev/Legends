CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id integer NOT NULL,
  starts_at timestamptz NOT NULL,
  email text NOT NULL
);
CREATE INDEX ON bookings (staff_id, starts_at);
