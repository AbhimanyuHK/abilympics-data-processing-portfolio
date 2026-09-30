# Reservation Competition Practice Workbook

A concrete Excel implementation of the reservation-processing practice workflow.

## Workbook

Local generated artifact: `reservation_competition_practice.xlsx`

Sheets:
1. `Instructions` — workflow and operating rules
2. `Raw_Data` — frozen source reservation data
3. `Cleaned_Data` — analysis-ready reservation table
4. `Lookups` — valid statuses and expected reconciliation metrics
5. `Validation` — repeatable validation checks and final gate
6. `Exceptions` — traceable exception/review log
7. `Report` — competition-style summary
8. Supporting lookup/data tables

## Processing flow

`Raw_Data -> Cleaned_Data -> Validation + Exceptions -> Report`

The raw sheet is preserved. Validation is separated from the final report so the candidate can demonstrate correctness before presentation.

## Baseline reconciliation

- Countries: 6
- Members: 8
- Travel records: 6
- Airlines: 6
- Schedules: 6
- Reservations: 12
- Confirmed: 8
- Cancelled: 2
- Pending: 2
- Total travel price: 5950.00

## Timed drill

Suggested first pass: 35 minutes.

Target sequence:
- 5 min: inspect source
- 8 min: clean/standardize
- 8 min: validate and log exceptions
- 7 min: reconcile
- 7 min: build summary report

Then repeat from a blank workbook and reduce dependency on the prepared formulas.

> This is a personal practice artifact, not an official Abilympics task, workbook, or scoring template.
