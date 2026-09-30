# LibreOffice Base — Execution Runbook

## Objective

Build the reservation database from the repository's canonical CSV pack, then verify queries, forms, reports, and reconciliation under timed conditions.

## 1. Create the database

Create a new Base database named `abilympics_reservation_practice.odb`.

## 2. Import tables

Import in dependency order: country.csv, member.csv, travel.csv, airline.csv, schedule.csv, reservation.csv.

During import preserve headers, choose appropriate numeric/date/time/text types, do not auto-generate existing IDs, and verify row counts immediately.

Expected baseline counts: COUNTRY 6; MEMBER 8; TRAVEL 6; AIRLINE 6; SCHEDULE 6; RESERVATION 12.

## 3. Configure structure

Apply `database/schema/travel-reservation-schema.md`. Create primary keys first, then foreign-key relationships and useful indexes. Do not redesign the business model merely to fit the GUI.

## 4. Build queries

Use `libreoffice-base/queries/query-implementation-checklist.md`. Save Q01–Q10 before reports. Keep DQ01–DQ05 separate so analytical queries do not silently clean or discard records.

## 5. Build forms

Implement F01–F04 from `libreoffice-base/forms/README.md`. Prefer combo/list controls for foreign keys and prioritize functional usability over decoration.

## 6. Build reports

Implement the seven reports from `libreoffice-base/reports/README.md`. Every report must use a saved query as its source.

## 7. Final verification

Record row counts, relationship integrity, query execution, form create/search/update tests, report totals, and data-quality results. Reconcile the accepted clean dataset against baseline counts before finishing.

## 8. Timed targets

First build: 80 minutes.

After repetition: import/structure 20 min; queries 20 min; forms 10 min; reports/navigation 10 min; validation 5 min.

Target: **65 minutes**, leaving contingency for competition-day differences.

## Important limitation

The repository provides the reproducible specification and source data. The actual `.odb` file should be created and tested in a local LibreOffice environment rather than represented as a documentation-only artifact.
