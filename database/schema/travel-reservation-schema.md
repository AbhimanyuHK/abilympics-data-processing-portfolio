# Travel Reservation & Data Management System

## Purpose
A competition-oriented relational database exercise for practising database design, normalization, relationships, constraints, queries, validation, forms, and reporting.

## Entities

### COUNTRY
| Column | Type | Rule |
|---|---|---|
| country_id | INTEGER | PK |
| country_code | CHAR(3) | UNIQUE, NOT NULL |
| country_name | VARCHAR(100) | UNIQUE, NOT NULL |

### MEMBER
| Column | Type | Rule |
|---|---|---|
| member_id | INTEGER | PK |
| first_name | VARCHAR(60) | NOT NULL |
| last_name | VARCHAR(60) | NOT NULL |
| email | VARCHAR(150) | UNIQUE, NOT NULL |
| country_id | INTEGER | FK → COUNTRY |
| membership_date | DATE | NOT NULL |
| status | VARCHAR(20) | ACTIVE / INACTIVE |

### TRAVEL
| Column | Type | Rule |
|---|---|---|
| travel_id | INTEGER | PK |
| destination | VARCHAR(120) | NOT NULL |
| country_id | INTEGER | FK → COUNTRY |
| departure_date | DATE | NOT NULL |
| return_date | DATE | NOT NULL |
| price | DECIMAL(12,2) | >= 0 |

### AIRLINE
| Column | Type | Rule |
|---|---|---|
| airline_id | INTEGER | PK |
| airline_name | VARCHAR(120) | UNIQUE, NOT NULL |
| country_id | INTEGER | FK → COUNTRY |

### SCHEDULE
| Column | Type | Rule |
|---|---|---|
| schedule_id | INTEGER | PK |
| travel_id | INTEGER | FK → TRAVEL |
| airline_id | INTEGER | FK → AIRLINE |
| departure_time | DATETIME | NOT NULL |
| arrival_time | DATETIME | NOT NULL |
| gate | VARCHAR(20) | NULL |

### RESERVATION
| Column | Type | Rule |
|---|---|---|
| reservation_id | INTEGER | PK |
| member_id | INTEGER | FK → MEMBER |
| schedule_id | INTEGER | FK → SCHEDULE |
| reservation_date | DATE | NOT NULL |
| status | VARCHAR(20) | RESERVED / CANCELLED / COMPLETED |
| seat_number | VARCHAR(10) | NULL |

## Relationships
- COUNTRY 1 → N MEMBER
- COUNTRY 1 → N TRAVEL
- COUNTRY 1 → N AIRLINE
- TRAVEL 1 → N SCHEDULE
- AIRLINE 1 → N SCHEDULE
- MEMBER 1 → N RESERVATION
- SCHEDULE 1 → N RESERVATION

## Integrity Rules
1. Every foreign key must reference an existing parent record.
2. Travel return date must not be earlier than departure date.
3. Schedule arrival must be later than departure.
4. Price cannot be negative.
5. Member email must be unique.
6. Country code must be unique.
7. Reservation status must use an approved value.
8. Duplicate reservation records should be detected.
9. A cancelled reservation should not be treated as an active booking.
10. Required fields must not be silently populated with fabricated values.

## Normalization Target
The design targets Third Normal Form (3NF): each table represents one logical entity, repeating groups are removed, non-key attributes depend on the whole primary key, and transitive dependencies are separated where appropriate.
