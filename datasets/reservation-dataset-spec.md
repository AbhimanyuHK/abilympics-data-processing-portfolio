# Reservation Dataset Specification

## Baseline Dataset

The baseline dataset represents a small international travel-reservation system.

### Tables

- country: 6 records
- member: 8 records
- travel: 6 records
- airline: 6 records
- schedule: 6 records
- reservation: 12 records

## Expected Characteristics

The clean dataset should contain:

- No orphan foreign keys
- No duplicate member emails
- No invalid travel dates
- No negative prices
- No invalid schedule times
- Only approved reservation statuses

## Dataset Versions

| Version | Purpose |
|---|---|
| v1.0 | Clean baseline |
| v1.1 | Dirty-data exercise |
| v1.2 | Larger-volume performance exercise |

Future versions should document the exact changes from the previous version.
