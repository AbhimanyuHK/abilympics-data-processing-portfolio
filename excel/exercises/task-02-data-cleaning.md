# Excel Task 02 — Controlled Data Cleaning

## Scenario
A reservation source contains formatting inconsistencies, missing values, invalid references, duplicate candidates, and date/amount anomalies.

## Tasks
### A. Standardization
- trim leading/trailing whitespace
- normalize email casing
- standardize status values
- standardize date representation
- preserve original values for audit

### B. Validation
Create checks for:
- required fields
- valid country/reference values
- valid reservation status
- non-negative price
- return date >= departure date
- arrival time >= departure time
- duplicate reservation candidates

### C. Exception handling
Every rejected or review-required row must have:
- source record ID
- issue type
- issue description
- action
- automation-safe flag
- human-review flag
- final status

### D. Reconciliation
Demonstrate:
source rows = clean rows + rejected rows + review rows

Reconcile record count, reservation count, and total travel price where applicable.

## Time target
35 minutes.

## Completion standard
The workbook must allow another person to understand what changed, why it changed, and which records still require review.
