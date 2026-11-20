# Sara books Mona at 10:00 for 30 minutes
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'sara@example.com', '[2026-12-01 10:00+02, 2026-12-01 10:30+02)')"
INSERT 0 1
# Karim tries Mona at 10:15: the database refuses
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'karim@example.com', '[2026-12-01 10:15+02, 2026-12-01 10:45+02)')"
ERROR:  conflicting key value violates exclusion constraint "no_double_booking"
DETAIL:  Key (staff_id, during)=(1, ["2026-12-01 08:15:00+00","2026-12-01 08:45:00+00")) conflicts with existing key (staff_id, during)=(1, ["2026-12-01 08:00:00+00","2026-12-01 08:30:00+00")).
# The same time with Omar is fine
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (2, 1, 'karim@example.com', '[2026-12-01 10:15+02, 2026-12-01 10:45+02)')"
INSERT 0 1
# 10:30 with Mona is fine too: the ranges only touch
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'nour@example.com', '[2026-12-01 10:30+02, 2026-12-01 11:00+02)')"
INSERT 0 1
# Sara cancels, and 10:00 is free again
$ psql shop -c "UPDATE bookings SET status = 'cancelled' WHERE id = 1"
UPDATE 1
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'karim@example.com', '[2026-12-01 10:00+02, 2026-12-01 10:30+02)')"
INSERT 0 1
