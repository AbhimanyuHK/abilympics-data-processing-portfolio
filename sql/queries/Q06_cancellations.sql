SELECT
    r.reservation_id, m.first_name, m.last_name,
    t.destination, r.reservation_date, r.seat_number
FROM reservation r
JOIN member m ON m.member_id = r.member_id
JOIN schedule s ON s.schedule_id = r.schedule_id
JOIN travel t ON t.travel_id = s.travel_id
WHERE r.status = 'CANCELLED'
ORDER BY r.reservation_date DESC;
