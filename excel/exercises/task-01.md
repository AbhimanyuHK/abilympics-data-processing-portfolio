# Excel Task 01 — Data Profiling and Cleaning

## Objective
Transform a small raw reservation dataset into a clean, validated analysis table without losing traceability.

## Input
Use:
- datasets/dirty-data-raw.csv
- datasets/dirty-data-spec.md

## Tasks
1. Import the source data into Excel.
2. Preserve the raw sheet unchanged.
3. Profile row count, blank count, duplicate candidates, invalid references, invalid date/range values, and numeric anomalies.
4. Create a cleaned working table.
5. Standardize whitespace and casing where deterministic.
6. Flag invalid references instead of inventing replacements.
7. Flag missing required values.
8. Identify duplicate candidates.
9. Create an exception log.
10. Reconcile raw rows against cleaned + rejected/review rows.

## Required deliverables
- Raw sheet
- Cleaned sheet
- Validation sheet
- Exception log
- Reconciliation sheet

## Time target
30 minutes for the first attempt.

## Scoring mindset
accuracy -> traceability -> validation -> speed

Do not silently delete problematic records.
