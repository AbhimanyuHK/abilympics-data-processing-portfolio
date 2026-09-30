-- Q08: Reservation value by member.
-- Cancelled reservations are excluded.

SELECT
    m.member_id,
    m.first_name,
    m.last_name,
    COUNT(r.reservation_id) AS valid_reservations,
    COALESCE(SUM(t.price), 0) AS total_value
FROM member m
LEFT JOIN reservation r
    ON r.member_id = m.member_id
   AND r.status IN ('RESERVED','COMPLETED')
LEFT JOIN schedule s ON s.schedule_id = r.schedule_id
LEFT JOIN travel t ON t.travel_id = s.travel_id
GROUP BY m.member_id, m.first_name, m.last_name
ORDER BY total_value DESC;
