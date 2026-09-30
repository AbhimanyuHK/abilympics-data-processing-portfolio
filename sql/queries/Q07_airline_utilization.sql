-- Q07: Airline utilization by reservation status.

SELECT
    a.airline_name,
    COUNT(r.reservation_id) AS total_reservations,
    SUM(CASE WHEN r.status = 'RESERVED' THEN 1 ELSE 0 END) AS active_reservations,
    SUM(CASE WHEN r.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_reservations,
    SUM(CASE WHEN r.status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_reservations
FROM airline a
JOIN schedule s ON s.airline_id = a.airline_id
LEFT JOIN reservation r ON r.schedule_id = s.schedule_id
GROUP BY a.airline_id, a.airline_name
ORDER BY total_reservations DESC, a.airline_name;
