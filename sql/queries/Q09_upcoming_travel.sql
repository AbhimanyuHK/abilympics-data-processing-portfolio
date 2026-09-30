-- Q09: Upcoming travel schedule with active reservations.

SELECT
    t.destination,
    t.departure_date,
    t.return_date,
    a.airline_name,
    s.departure_time,
    s.arrival_time,
    COUNT(r.reservation_id) AS active_reservations
FROM travel t
JOIN schedule s ON s.travel_id = t.travel_id
JOIN airline a ON a.airline_id = s.airline_id
LEFT JOIN reservation r
    ON r.schedule_id = s.schedule_id
   AND r.status = 'RESERVED'
GROUP BY
    t.travel_id, t.destination, t.departure_date, t.return_date,
    a.airline_name, s.departure_time, s.arrival_time
ORDER BY t.departure_date;
