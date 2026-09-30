SELECT
    m.member_id, m.first_name, m.last_name,
    t.destination, t.departure_date, t.return_date, r.status
FROM member m
JOIN reservation r ON r.member_id = m.member_id
JOIN schedule s ON s.schedule_id = r.schedule_id
JOIN travel t ON t.travel_id = s.travel_id
WHERE m.member_id = :member_id
ORDER BY t.departure_date DESC;
