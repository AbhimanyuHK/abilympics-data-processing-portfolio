-- Q11: Detect duplicate reservation attempts.

SELECT
    member_id,
    schedule_id,
    COUNT(*) AS reservation_count,
    MIN(reservation_id) AS first_reservation_id,
    MAX(reservation_id) AS last_reservation_id
FROM reservation
GROUP BY member_id, schedule_id
HAVING COUNT(*) > 1
ORDER BY reservation_count DESC;
