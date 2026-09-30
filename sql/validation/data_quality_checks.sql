-- Each query returns records requiring review.

SELECT m.*
FROM member m
LEFT JOIN country c ON c.country_id = m.country_id
WHERE c.country_id IS NULL;

SELECT *
FROM travel
WHERE return_date < departure_date;

SELECT *
FROM travel
WHERE price < 0;

SELECT *
FROM schedule
WHERE arrival_time <= departure_time;

SELECT *
FROM reservation
WHERE status NOT IN ('RESERVED', 'CANCELLED', 'COMPLETED');

SELECT email, COUNT(*) AS duplicate_count
FROM member
GROUP BY email
HAVING COUNT(*) > 1;

SELECT member_id, schedule_id, COUNT(*) AS duplicate_count
FROM reservation
GROUP BY member_id, schedule_id
HAVING COUNT(*) > 1;

SELECT r.*
FROM reservation r
LEFT JOIN member m ON m.member_id = r.member_id
LEFT JOIN schedule s ON s.schedule_id = r.schedule_id
WHERE m.member_id IS NULL OR s.schedule_id IS NULL;
