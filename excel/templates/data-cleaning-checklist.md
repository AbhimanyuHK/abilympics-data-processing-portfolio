# Excel Data Cleaning Checklist

## Source control
- [ ] Raw source preserved
- [ ] Dataset version recorded
- [ ] Import date recorded
- [ ] Source row count captured

## Structure
- [ ] Headers are unique
- [ ] Required columns exist
- [ ] Data types are appropriate
- [ ] No unexpected columns are silently ignored

## Quality
- [ ] Missing required values checked
- [ ] Duplicate candidates checked
- [ ] Reference values checked
- [ ] Date ranges checked
- [ ] Numeric ranges checked
- [ ] Text formatting checked

## Transformation
- [ ] Rules documented
- [ ] Deterministic corrections separated from ambiguous cases
- [ ] Original values retained where auditability matters

## Reconciliation
- [ ] Input/output row counts reconciled
- [ ] Key totals reconciled
- [ ] Exception counts reconciled

## Final review
- [ ] Filters cleared
- [ ] Formulas checked
- [ ] Pivot/report refreshed
- [ ] Exceptions reviewed
- [ ] Final workbook saved with version
