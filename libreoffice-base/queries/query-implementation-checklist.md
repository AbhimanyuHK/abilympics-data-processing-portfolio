# LibreOffice Base Query Implementation Checklist

Implement the logical query set against the same reservation schema used by the SQL and Access tracks.

## Required queries

- Q01 Member reservation history
- Q02 Reservations by country
- Q03 Travel duration
- Q04 Destination revenue
- Q05 Member history
- Q06 Cancellations
- Q07 Airline utilization
- Q08 Member spend
- Q09 Upcoming travel
- Q10 Country summary

## Data-quality queries

- DQ01 Missing required values
- DQ02 Invalid references
- DQ03 Invalid status values
- DQ04 Duplicate candidates
- DQ05 Date/value rule violations

## Implementation rule

Create each query as a saved query in Base, run it against the imported tables, and record the result shape and verification status in the build notes.

Do not silently correct source data inside analytical queries. Cleaning belongs in a controlled processing step; analytical queries should operate on the accepted dataset.

## Verification

For each saved query confirm:

- expected columns are present
- joins use PK/FK relationships
- filters match the written requirement
- aggregates reconcile with the baseline dataset
- no accidental duplicate multiplication occurs
- output is readable under timed conditions
