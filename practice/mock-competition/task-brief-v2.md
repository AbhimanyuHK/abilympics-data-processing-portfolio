# Mock Competition Task V2 — Travel Reservation Processing

> Personal practice exercise. Not an official Abilympics task.

## Scenario

You are given a small travel-reservation dataset for an international membership organization. The source contains member, country, travel, airline, schedule, and reservation information.

You must transform the source into a reliable relational solution and produce user-facing outputs.

## Part A — Database design

Create the relational model with:
- COUNTRY
- MEMBER
- TRAVEL
- AIRLINE
- SCHEDULE
- RESERVATION

Requirements:
- primary keys
- foreign keys/relationships
- appropriate data types
- required fields
- reasonable uniqueness constraints

## Part B — Data processing

Using the supplied clean and dirty datasets:
1. profile the source
2. identify defects
3. standardize deterministic formatting issues
4. separate invalid/review records
5. document corrections
6. reconcile source and processed records

## Part C — Queries

Produce:
1. member reservation history
2. reservations by country
3. travel duration
4. destination revenue
5. cancellation summary
6. airline utilization
7. member spend
8. upcoming travel
9. duplicate candidates
10. data-quality exceptions

## Part D — Excel

Produce:
- cleaned data table
- validation sheet
- exception log
- reconciliation sheet
- summary report

## Part E — Access

Produce:
- relational tables
- relationships
- saved queries
- member search form
- reservation entry/update workflow
- administrator navigation
- at least two reports

## Part F — Final verification

Demonstrate:
- row-count reconciliation
- key aggregate reconciliation
- reference integrity
- representative record checks
- exception traceability

## Timebox

**180 minutes**

Suggested allocation:
- 15 min requirements/design
- 30 min database
- 35 min data processing
- 35 min queries
- 30 min Excel/Access interface
- 20 min reports
- 15 min final verification

Adjust allocation after reviewing your own timing data.

## Source data

Use:
- datasets/access-import/
- datasets/dirty-data-raw.csv
- datasets/dirty-data-spec.md
