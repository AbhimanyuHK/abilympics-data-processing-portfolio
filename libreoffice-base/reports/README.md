# LibreOffice Base Reports — Implementation Specification

All reports must be built from saved queries so that report output remains traceable and reproducible.

## Required reports

1. Reservation Summary — reservation count by status and destination.
2. Member Travel History — member, reservation, destination, airline, travel dates and status.
3. Destination Revenue — destination, reservation count and revenue based on the accepted revenue rule.
4. Country Summary — country, member count, reservation count and related summary measures.
5. Airline Utilization — airline, schedule count and reservation count.
6. Cancellation Summary — cancelled reservations by date, country and destination.
7. Data Quality Exceptions — exception type, source record, field, observed value and resolution/status.

## Build pattern

For each report:
- create or select the saved query first
- verify query output independently
- create the Base report from that query
- add a clear title and generated-date field
- format dates consistently
- format monetary values consistently
- use grouping only where it improves timed readability
- avoid decorative elements that consume build time

## Verification checklist

Every report must be traceable to one saved query.

Verify:
- totals reconcile with the accepted dataset
- filters and parameters behave as intended
- date formatting is consistent
- numeric/currency formatting is consistent
- representative records are present
- cancelled/invalid records follow the documented reporting rule
- no accidental duplicate rows are introduced

## Timed target

Build the core reports in 30 minutes:
- Reservation Summary: 5 min
- Member Travel History: 5 min
- Destination Revenue: 5 min
- Country Summary: 5 min
- Airline/Cancellation: 5 min
- DQ Exceptions: 5 min
