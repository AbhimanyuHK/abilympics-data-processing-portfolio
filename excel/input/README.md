# Excel Input Data

This directory contains source datasets used for Excel-based competition practice.

## Processing pattern

Raw workbook / CSV -> Profile -> Clean and standardize -> Validate -> Reconcile -> Processed workbook -> Pivot / summary / report

## Rules
- Preserve the original source data.
- Do not overwrite raw values during cleaning.
- Record every transformation that changes data.
- Separate deterministic corrections from human-review cases.
- Reconcile row counts and key totals before producing the final report.

Planned workbook: reservation_raw.xlsx.
