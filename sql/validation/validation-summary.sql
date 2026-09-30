-- Expected validation summary for the clean baseline.
-- Each metric should return zero exceptions unless the dataset is intentionally dirty.

SELECT 'orphan_member_country' AS check_name, COUNT(*) AS exception_count
FROM member m LEFT JOIN country c ON c.country_id=m.country_id
WHERE c.country_id IS NULL
UNION ALL
SELECT 'invalid_travel_dates', COUNT(*)
FROM travel WHERE return_date < departure_date
UNION ALL
SELECT 'negative_travel_price', COUNT(*)
FROM travel WHERE price < 0
UNION ALL
SELECT 'invalid_schedule_times', COUNT(*)
FROM schedule WHERE arrival_time <= departure_time
UNION ALL
SELECT 'invalid_reservation_status', COUNT(*)
FROM reservation
WHERE status NOT IN ('RESERVED','CANCELLED','COMPLETED')
UNION ALL
SELECT 'duplicate_member_email', COUNT(*)
FROM (SELECT email FROM member GROUP BY email HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'duplicate_reservation', COUNT(*)
FROM (SELECT member_id,schedule_id FROM reservation GROUP BY member_id,schedule_id HAVING COUNT(*) > 1) d;
