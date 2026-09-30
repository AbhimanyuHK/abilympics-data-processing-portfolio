SELECT
    t.destination,
    COUNT(r.reservation_id) AS reservation_count,
    SUM(t.price) AS total_value
FROM reservation r
JOIN schedule s ON s.schedule_id = r.schedule_id
JOIN travel t ON t.travel_id = s.travel_id
WHERE r.status IN ('RESERVED', 'COMPLETED')
GROUP BY t.travel_id, t.destination
ORDER BY total_value DESC;
