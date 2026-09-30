# LibreOffice Base Import Guide

## 1. Create a database

Open LibreOffice Base and create a new database.

Recommended name:

`abilympics_reservation_practice.odb`

## 2. Import CSV files

Use:

`libreoffice-base/data-import/`

or the canonical dataset:

`datasets/access-import/`

Import reference tables first:

1. COUNTRY
2. MEMBER_STATUS
3. RESERVATION_STATUS

Then dependent entities:

4. MEMBER
5. TRAVEL
6. AIRLINE
7. SCHEDULE
8. RESERVATION

## 3. Configure data types

Review imported columns and explicitly set:
- integer identifiers
- text fields
- date fields
- time fields
- decimal price fields

Do not rely blindly on automatic type detection.

## 4. Create relationships

Create the documented 1:N relationships and enable referential integrity.

## 5. Verify

Compare row counts with the expected clean baseline in `practice/answer-key/sql-expected-results.md`.

Expected counts:
- COUNTRY: 6
- MEMBER_STATUS: 2
- MEMBER: 8
- TRAVEL: 6
- AIRLINE: 6
- SCHEDULE: 6
- RESERVATION_STATUS: 3
- RESERVATION: 12
