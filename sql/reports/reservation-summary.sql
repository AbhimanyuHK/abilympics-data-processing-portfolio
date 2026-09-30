-- Management summary report.

SELECT
    COUNT(*) AS total_reservations,
    SUM(CASE WHEN status = 'RESERVED' THEN 1 ELSE 0 END) AS active_reservations,
    SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_reservations,
    SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_reservations
FROM reservation;
