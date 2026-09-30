# Access Form Specifications

## F01 — Member Search
Inputs: Member ID, First name, Last name, Country, Status.
Outputs: member details, reservation list, schedule/travel details.
Validation: optional filters may be blank; show a clear no-results state.

## F02 — Reservation Entry
Required: Member, Schedule, Reservation date, Status.
Optional: Seat number.
Validation: member and schedule must exist; status must use the approved domain; date must be valid; duplicate candidates should be flagged.

## F03 — Reservation Update
Locate an existing reservation, update allowed fields, revalidate, then save.

## F04 — Administrator Dashboard
Navigation: Member Search, Reservation Entry, Reservation Update, Reports, Data Quality, Exit.
