CREATE TABLE conversations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  last_seq integer NOT NULL DEFAULT 0
);
CREATE TABLE messages (
  conversation_id bigint NOT NULL REFERENCES conversations (id),
  seq integer NOT NULL,
  body text NOT NULL,
  sent_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (conversation_id, seq)
);

-- كل محادثة تعدّ رسائلها: بلا فجوات ولا إعادة ترتيب، ومتابعة سهلة
CREATE FUNCTION send(conversation bigint, text text) RETURNS integer AS $$
  WITH next AS (
    UPDATE conversations SET last_seq = last_seq + 1 WHERE id = conversation RETURNING last_seq
  )
  INSERT INTO messages (conversation_id, seq, body)
  SELECT conversation, last_seq, text FROM next
  RETURNING seq;
$$ LANGUAGE sql;
