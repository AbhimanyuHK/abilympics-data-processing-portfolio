-- Controlled dirty-data exercise.
-- DO NOT run against the clean baseline without understanding the intended defects.
-- This file adds a separate set of intentionally problematic records.

INSERT INTO member (member_id, first_name, last_name, email, country_id, membership_date, status) VALUES
(1101,'Ananya','Rao','ANANYA.RAO@example.org',1,'2025-01-10','ACTIVE');

-- Invalid foreign-key reference: requires a staging/landing table or deliberate
-- validation before loading into the constrained production schema.
-- Example defect records are represented below as raw CSV-style rows.
