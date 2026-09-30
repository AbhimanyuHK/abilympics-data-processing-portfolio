# Task 04 — Dirty Data Processing

## Objective

Start with imperfect source data, identify every quality issue, classify the issue, and produce a validated clean output.

## Workflow

1. Inspect the source.
2. Profile columns and values.
3. Identify validation rules.
4. Separate valid and invalid records.
5. Standardize safe transformations.
6. Produce an exception report.
7. Correct only deterministic issues.
8. Flag ambiguous issues for review.
9. Load the clean result.
10. Re-run validation.

## Defect Classes

- Missing values
- Invalid references
- Duplicate records
- Formatting inconsistencies
- Invalid dates
- Invalid numeric values
- Invalid status values
- Referential-integrity failures

## Required Evidence

- Source record count
- Valid record count
- Rejected/exception count
- Issue counts by category
- Clean output
- Exception report
- Validation result after processing

## Initial Time Target

45 minutes.

## Rule

Do not silently delete bad records. Every rejected record must remain traceable to its source.
