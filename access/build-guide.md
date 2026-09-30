# Microsoft Access Build Guide

## Phase 1 — Create database
Create a new `.accdb` file named `abilympics_reservation_practice.accdb`.

## Phase 2 — Import source data
Use the clean baseline represented by `database/sample-data/seed-data.sql`. For Windows/Access practice, an equivalent CSV import can be used.

## Phase 3 — Create tables
Create COUNTRY, MEMBER, TRAVEL, AIRLINE, SCHEDULE, and RESERVATION. Set primary keys and appropriate field types.

## Phase 4 — Relationships
Create the documented 1:N relationships and enable referential integrity where appropriate.

## Phase 5 — Queries
Implement the queries in `access/query-specifications.md`.

## Phase 6 — Forms
Build F01–F04 using the form specifications.

## Phase 7 — Reports
Build the required reports from saved queries.

## Phase 8 — Verification
Test valid insertion, invalid-value handling, search, update, reports, totals, relationships, and navigation.

## Timed target
First complete build: 90 minutes. Later target: 60 minutes.
