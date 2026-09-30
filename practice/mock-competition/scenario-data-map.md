# Scenario Data Map

## Source files

| File | Entity | Primary key | Main reference |
|---|---|---|---|
| country.csv | COUNTRY | country_id | — |
| member.csv | MEMBER | member_id | country_id |
| travel.csv | TRAVEL | travel_id | country_id |
| airline.csv | AIRLINE | airline_id | country_id |
| schedule.csv | SCHEDULE | schedule_id | travel_id, airline_id |
| reservation.csv | RESERVATION | reservation_id | member_id, schedule_id |

## Dependency order

COUNTRY
→ MEMBER / TRAVEL / AIRLINE
→ SCHEDULE
→ RESERVATION

Use this order when loading the database or diagnosing reference failures.
