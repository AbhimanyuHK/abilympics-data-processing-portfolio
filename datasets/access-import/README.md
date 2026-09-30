# Access / Excel Import Pack

This folder contains CSV files designed for timed Microsoft Access and Excel practice.

## Import order

1. country.csv
2. member.csv
3. travel.csv
4. airline.csv
5. schedule.csv
6. reservation.csv

Import parent tables before child tables so relationships can be validated.

## Validation

After import, verify:
- row counts
- primary-key uniqueness
- reference integrity
- date/time fields
- numeric values
- reservation status domain

The canonical relational definition remains in database/schema/travel-reservation-schema.md.
