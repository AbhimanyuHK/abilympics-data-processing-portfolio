SELECT
    r.reservation_id, m.member_id, m.first_name, m.last_name,
    t.destination, s.departure_time, s.arrival_time,
    r.seat_number, r.status
FROM reservation r
JOIN member m ON m.member_id = r.member_id
JOIN schedule s ON s.schedule_id = r.schedule_id
JOIN travel t ON t.travel_id = s.travel_id
ORDER BY s.departure_time, m.last_name, m.first_name;
