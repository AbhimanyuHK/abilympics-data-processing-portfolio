# LibreOffice Base Schema

Use the same logical model as the SQL and Access tracks.

## Tables

COUNTRY
- country_id — primary key
- country_code — unique business key
- country_name — unique

MEMBER
- member_id — primary key
- first_name
- last_name
- email — unique
- country_id — foreign key
- membership_date
- status

TRAVEL
- travel_id — primary key
- destination
- country_id — foreign key
- departure_date
- return_date
- price

AIRLINE
- airline_id — primary key
- airline_name — unique
- country_id — foreign key

SCHEDULE
- schedule_id — primary key
- travel_id — foreign key
- airline_id — foreign key
- departure_time
- arrival_time
- gate

RESERVATION
- reservation_id — primary key
- member_id — foreign key
- schedule_id — foreign key
- reservation_date
- status
- seat_number

## Relationship map

COUNTRY 1:N MEMBER
COUNTRY 1:N TRAVEL
COUNTRY 1:N AIRLINE
TRAVEL 1:N SCHEDULE
AIRLINE 1:N SCHEDULE
MEMBER 1:N RESERVATION
SCHEDULE 1:N RESERVATION

Target: normalized relational design with referential integrity.
