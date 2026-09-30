-- Audit rules for datasets/dirty-data-raw.csv after loading it into staging tables.
-- The objective is to identify exceptions before production loading.

-- Missing required member name
SELECT *
FROM staging_member
WHERE NULLIF(TRIM(first_name),'') IS NULL;

-- Invalid country reference
SELECT m.*
FROM staging_member m
LEFT JOIN country c ON c.country_id=m.country_id
WHERE c.country_id IS NULL;

-- Email normalization candidates
SELECT *
FROM staging_member
WHERE email <> LOWER(TRIM(email));

-- Invalid travel date range
SELECT *
FROM staging_travel
WHERE return_date < departure_date;

-- Invalid price
SELECT *
FROM staging_travel
WHERE price < 0;

-- Invalid schedule chronology
SELECT *
FROM staging_schedule
WHERE arrival_time <= departure_time;

-- Invalid reservation schedule reference
SELECT r.*
FROM staging_reservation r
LEFT JOIN schedule s ON s.schedule_id=r.schedule_id
WHERE s.schedule_id IS NULL;

-- Duplicate reservation candidate
SELECT member_id,schedule_id,COUNT(*) AS record_count
FROM staging_reservation
GROUP BY member_id,schedule_id
HAVING COUNT(*) > 1;
