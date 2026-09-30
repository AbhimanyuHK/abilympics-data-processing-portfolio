# Final Verification Protocol

Run this protocol during the final 10–15 minutes of a timed attempt.

## 1. Structural verification
- Confirm all required tables/objects exist.
- Confirm primary keys.
- Confirm relationships.
- Confirm expected source row counts.

## 2. Data verification
- Check required fields.
- Check duplicates.
- Check references.
- Check date/time logic.
- Check numeric ranges.
- Check status/domain values.

## 3. Result verification
- Run required queries.
- Compare key aggregates with independent calculations.
- Sample several records from source to final output.

## 4. Interface verification
- Open each required form.
- Test one valid action.
- Test one invalid action.
- Verify navigation.

## 5. Report verification
- Refresh/report from saved query.
- Check titles and filters.
- Check totals.
- Ensure no manual totals were introduced.

## 6. Submission hygiene
- Save the final version.
- Confirm filenames.
- Confirm no temporary/debug sheets are exposed.
- Preserve the raw source.
- Record unresolved issues.

Never use the final review to hide an error. Record it and, if time permits, correct it with traceability.
