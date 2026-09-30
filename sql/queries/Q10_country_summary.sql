-- Q10: Country-level member and reservation summary.

SELECT
    c.country_name,
    COUNT(DISTINCT m.member_id) AS members,
    COUNT(r.reservation_id) AS reservations,
    SUM(CASE WHEN r.status = 'RESERVED' THEN 1 ELSE 0 END) AS active_reservations,
    SUM(CASE WHEN r.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancellations
FROM country c
LEFT JOIN member m ON m.country_id = c.country_id
LEFT JOIN reservation r ON r.member_id = m.member_id
GROUP BY c.country_id, c.country_name
ORDER BY members DESC, c.country_name;
