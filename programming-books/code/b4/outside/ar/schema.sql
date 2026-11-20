CREATE TABLE businesses (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  logo_key text
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses (id),
  email text NOT NULL,
  status text NOT NULL CHECK (status IN ('awaiting_deposit', 'confirmed', 'cancelled'))
);
CREATE TABLE payments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  booking_id bigint NOT NULL REFERENCES bookings (id),
  amount integer NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed')),
  checkout_id text UNIQUE
);
CREATE TABLE webhook_events (
  id text PRIMARY KEY,
  received_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE outbox (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  recipient text NOT NULL,
  subject text NOT NULL,
  body text NOT NULL,
  sent_at timestamptz
);
INSERT INTO businesses (name) VALUES ('صالون بِت');
INSERT INTO bookings (business_id, email, status) VALUES (1, 'sara@example.com', 'awaiting_deposit');
