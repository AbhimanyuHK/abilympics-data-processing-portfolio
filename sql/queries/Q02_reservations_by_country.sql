SELECT
    c.country_name,
    COUNT(r.reservation_id) AS reservation_count
FROM country c
JOIN member m ON m.country_id = c.country_id
LEFT JOIN reservation r ON r.member_id = m.member_id
GROUP BY c.country_id, c.country_name
ORDER BY reservation_count DESC, c.country_name;
