# LibreOffice Base Import Guide

## 1. Create a database

Open LibreOffice Base and create a new database.

Recommended name:

abilympics_reservation_practice.odb

## 2. Import CSV files

Use:

libreoffice-base/data-import/

or the canonical dataset:

datasets/access-import/

Import parent entities first:

1. COUNTRY
2. MEMBER
3. TRAVEL
4. AIRLINE
5. SCHEDULE
6. RESERVATION

## 3. Configure data types

Review imported columns and explicitly set:
- integer identifiers
- text fields
- date fields
- time fields
- decimal price fields

Do not rely blindly on automatic type detection.

## 4. Create relationships

Create the documented 1:N relationships.

Verify that invalid child references cannot be introduced when referential integrity is enabled.

## 5. Verify

Compare row counts with the expected clean baseline in:

practice/answer-key/sql-expected-results.md
