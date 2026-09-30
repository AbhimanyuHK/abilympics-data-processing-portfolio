SELECT
    travel_id, destination, departure_date, return_date,
    (return_date - departure_date) AS duration_days, price
FROM travel
ORDER BY departure_date;
