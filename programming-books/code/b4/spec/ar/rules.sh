# سارة تحجز منى الساعة 10:00 لثلاثين دقيقة
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'sara@example.com', '[2026-12-01 10:00+02, 2026-12-01 10:30+02)')"
INSERT 0 1
# كريم يحاول منى الساعة 10:15: قاعدة البيانات ترفض
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'karim@example.com', '[2026-12-01 10:15+02, 2026-12-01 10:45+02)')"
ERROR:  conflicting key value violates exclusion constraint "no_double_booking"
DETAIL:  Key (staff_id, during)=(1, ["2026-12-01 08:15:00+00","2026-12-01 08:45:00+00")) conflicts with existing key (staff_id, during)=(1, ["2026-12-01 08:00:00+00","2026-12-01 08:30:00+00")).
# الوقت نفسه مع عمر مقبول
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (2, 1, 'karim@example.com', '[2026-12-01 10:15+02, 2026-12-01 10:45+02)')"
INSERT 0 1
# 10:30 مع منى مقبول أيضاً: المديان يتلامسان فقط
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'nour@example.com', '[2026-12-01 10:30+02, 2026-12-01 11:00+02)')"
INSERT 0 1
# سارة تلغي، فيعود 10:00 متاحاً
$ psql shop -c "UPDATE bookings SET status = 'cancelled' WHERE id = 1"
UPDATE 1
$ psql shop -c "INSERT INTO bookings (staff_id, service_id, email, during) VALUES (1, 1, 'karim@example.com', '[2026-12-01 10:00+02, 2026-12-01 10:30+02)')"
INSERT 0 1
