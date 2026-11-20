CREATE TABLE businesses (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  -- الاسم بأحرف صغيرة، مرتباً بايتاً بايتاً (C): فهرس واحد يخدم البادئة والترتيب
  search_key text COLLATE "C" GENERATED ALWAYS AS (lower(name)) STORED
);
INSERT INTO businesses (name)
SELECT (ARRAY['Bit', 'Nour', 'Sara', 'Cairo', 'Nile', 'Delta', 'Star', 'Green'])[1 + i % 8] || ' '
    || (ARRAY['Hair', 'Clinic', 'Studio', 'Dental', 'Spa', 'Tutors', 'Garage', 'Barber'])[1 + (i / 8) % 8]
    || ' ' || i
  FROM generate_series(1, 500000) i;
-- text_pattern_ops يجعل LIKE 'prefix%' يستعمل الفهرس
CREATE INDEX businesses_name_prefix ON businesses (lower(name) text_pattern_ops);
CREATE INDEX businesses_search_key ON businesses (search_key);
ANALYZE businesses;
