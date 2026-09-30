# Data Quality Expected Results

The dirty-data exercise intentionally contains multiple independent defect categories.

## Expected defect categories
- whitespace/text normalization
- missing required value
- invalid country reference
- invalid date range
- negative price
- invalid schedule time relationship
- invalid schedule/reservation reference
- duplicate candidate
- invalid status where present

## Important

The expected number of final exceptions depends on the exact validation policy.

Do not hard-code a single score unless the exercise version and validation rules are frozen.

A correct submission should:
1. identify the source record,
2. identify the rule violated,
3. classify the action,
4. preserve traceability,
5. reconcile the final outcome.
