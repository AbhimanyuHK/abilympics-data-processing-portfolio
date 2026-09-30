# Microsoft Access Build Guide

## Phase 1 — Create database
Create a new `.accdb` file named `abilympics_reservation_practice.accdb`.

## Phase 2 — Import source data
Use the clean baseline represented by `datasets/access-import/`. Import reference tables before dependent tables.

Import order:
1. COUNTRY
2. MEMBER_STATUS
3. RESERVATION_STATUS
4. MEMBER
5. TRAVEL
6. AIRLINE
7. SCHEDULE
8. RESERVATION

## Phase 3 — Create tables
Create all eight tables. Set primary keys and appropriate field types. MEMBER.status_id and RESERVATION.status_id are foreign keys; do not create free-text status fields in those tables.

## Phase 4 — Relationships
Create the documented 1:N relationships and enable referential integrity where appropriate.

## Phase 5 — Queries
Implement the queries in `access/query-specifications.md`. Join status tables whenever a human-readable status is required in query output.

## Phase 6 — Forms
Build F01–F04 using the form specifications. Use combo/list controls for MEMBER_STATUS and RESERVATION_STATUS.

## Phase 7 — Reports
Build the required reports from saved queries.

## Phase 8 — Verification
Test valid insertion, invalid foreign-key handling, status selection, search, update, reports, totals, relationships, and navigation.

## Timed target
First complete build: 90 minutes. Later target: 60 minutes.
