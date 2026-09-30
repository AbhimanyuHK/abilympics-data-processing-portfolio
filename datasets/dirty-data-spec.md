# Dirty Data Exercise Specification

The next dataset version will intentionally introduce controlled defects.

## Defect Categories

1. Duplicate member email
2. Missing required member value
3. Invalid country reference
4. Invalid reservation status
5. Negative travel price
6. Return date before departure
7. Schedule arrival before departure
8. Duplicate reservation
9. Orphan reservation reference
10. Inconsistent text formatting

## Expected Output

For each defect, the solution should identify:

- Record/table
- Defect type
- Detection rule
- Recommended correction
- Whether correction is safe to automate
- Whether human review is required

No source record should be silently discarded.
