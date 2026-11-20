-- one partition per month; the parent table only routes rows to them
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY,
  staff_id integer NOT NULL,
  starts_at timestamptz NOT NULL,
  email text NOT NULL
) PARTITION BY RANGE (starts_at);

DO $$
DECLARE month date;
BEGIN
  FOR month IN SELECT generate_series(date '2025-01-01', date '2026-12-01', interval '1 month') LOOP
    EXECUTE format(
      'CREATE TABLE %I PARTITION OF bookings FOR VALUES FROM (%L) TO (%L)',
      'bookings_' || to_char(month, 'YYYY_MM'), month, month + interval '1 month');
  END LOOP;
END $$;

INSERT INTO bookings (staff_id, starts_at, email)
SELECT i % 500 + 1, timestamptz '2025-01-01' + i * interval '30 seconds', 'c' || i || '@example.com'
  FROM generate_series(1, 2000000) i;
ANALYZE bookings;
