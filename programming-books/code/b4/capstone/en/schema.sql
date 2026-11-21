CREATE EXTENSION btree_gist;

-- what each plan allows; NULL means no limit; prices in piastres a month
CREATE TABLE plans (
  id text PRIMARY KEY,
  monthly_bookings integer,
  price integer NOT NULL
);
INSERT INTO plans VALUES ('free', 5, 0), ('pro', NULL, 49900);

CREATE TABLE salons (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  plan text NOT NULL DEFAULT 'free' REFERENCES plans (id)
);
-- API keys are stored as hashes, like passwords
CREATE TABLE api_keys (
  hash text PRIMARY KEY,
  salon_id bigint NOT NULL REFERENCES salons (id)
);
-- every table that belongs to a salon carries salon_id
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  salon_id bigint NOT NULL REFERENCES salons (id),
  staff text NOT NULL,
  email text NOT NULL,
  during tstzrange NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (salon_id WITH =, staff WITH =, during WITH &&)
);
-- each provider event is applied once: its id is the primary key
CREATE TABLE billing_events (
  id text PRIMARY KEY,
  received_at timestamptz NOT NULL DEFAULT now()
);

-- row-level security: a query sees only the current salon's rows
ALTER TABLE salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
-- unset, or '' after a pooled connection used it: no rows at all
CREATE FUNCTION current_salon() RETURNS bigint LANGUAGE sql STABLE
  RETURN nullif(current_setting('app.salon_id', true), '')::bigint;
CREATE POLICY own_salon ON salons
  USING (id = current_salon());
CREATE POLICY own_bookings ON bookings
  USING (salon_id = current_salon());

-- the app connects as app_user, which cannot bypass these policies
CREATE ROLE app_user LOGIN PASSWORD 'app';
GRANT SELECT, INSERT, UPDATE ON salons, bookings, billing_events
  TO app_user;
GRANT SELECT ON plans, api_keys TO app_user;

-- two salons on the free plan, one already near its limit
INSERT INTO salons (name) VALUES ('Bit Hair Studio'), ('Nile Nails');
INSERT INTO api_keys VALUES
  (encode(sha256('key_a'), 'hex'), 1), (encode(sha256('key_b'), 'hex'), 2);
INSERT INTO bookings (salon_id, staff, email, during)
SELECT 1, 'Mona', 'guest@example.com', tstzrange(t, t + interval '30 min')
FROM generate_series(now() + interval '1 day', now() + interval '3 days',
                     interval '1 day') AS t;
INSERT INTO bookings (salon_id, staff, email, during) VALUES
  (2, 'Sara', 'nails@example.com', tstzrange(now(), now() + interval '1 h'));
