-- Q12: Reservation status distribution.

SELECT
    status,
    COUNT(*) AS reservation_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM reservation
GROUP BY status
ORDER BY reservation_count DESC;
