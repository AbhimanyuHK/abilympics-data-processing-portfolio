# Access Database Schema

This track recreates the competition-style relational database workflow in Microsoft Access.

## Core tables

- COUNTRY
- MEMBER_STATUS
- MEMBER
- TRAVEL
- AIRLINE
- SCHEDULE
- RESERVATION_STATUS
- RESERVATION

## Relationship design

- COUNTRY 1:N MEMBER
- COUNTRY 1:N TRAVEL
- COUNTRY 1:N AIRLINE
- MEMBER_STATUS 1:N MEMBER
- TRAVEL 1:N SCHEDULE
- AIRLINE 1:N SCHEDULE
- MEMBER 1:N RESERVATION
- SCHEDULE 1:N RESERVATION
- RESERVATION_STATUS 1:N RESERVATION

## Status domains

### MEMBER_STATUS

| status_id | status_code | status_name |
|---:|---|---|
| 1 | ACTIVE | Active |
| 2 | INACTIVE | Inactive |

### RESERVATION_STATUS

| status_id | status_code | status_name |
|---:|---|---|
| 1 | RESERVED | Reserved |
| 2 | CANCELLED | Cancelled |
| 3 | COMPLETED | Completed |

Use combo boxes/lookups in forms instead of allowing uncontrolled status text.

## Design requirements

- Primary keys on every entity and reference table
- Foreign keys enforced through Access relationships
- Appropriate required fields and data types
- Unique indexes for business identifiers where required
- Referential integrity enabled where appropriate
- Status values stored as foreign keys, not duplicated text
- Avoid storing derived values when they can be calculated safely
