# LibreOffice Base Forms — Implementation Specification

These forms are designed for timed practice and mirror the competition-oriented functional requirements.

## F01 — Member Search
Purpose: locate a member and inspect reservation history.
Controls: txtMemberID, txtLastName, cboCountry, btnSearch, btnClear, subReservations.
Expected result columns: member_id, member_name, country, email, reservation_id, destination, airline, departure_date, status, seat_number.
Validation: require at least one search criterion; keep result grid read-only; clear resets filters.

## F02 — Reservation Entry
Purpose: create a reservation safely.
Controls: txtReservationID, cboMember, cboSchedule, txtReservationDate, cboStatus, txtSeatNumber, btnSave, btnCancel.
Validation: member and schedule must exist; status must be CONFIRMED, CANCELLED, or PENDING; reservation date is required; reservation ID must be unique.
For timed practice, use combo/list controls backed by lookup queries rather than free-text foreign keys.

## F03 — Reservation Update
Purpose: locate and modify an existing reservation.
Controls: txtReservationID, btnFind, editable member/schedule/status/date/seat fields, btnSave, btnCancel.
Validation: reservation must exist; foreign keys remain valid; status remains within the approved domain; required fields remain populated; reservation ID cannot change to an existing ID.

## F04 — Administrator Navigation
Purpose: provide a compact control centre.
Navigation groups: Data (Member, Reservation); Queries (Q01–Q10); Data Quality (DQ01–DQ05); Reports (Reservation Summary, Country Summary, Destination Revenue, Cancellation, Airline Utilization); Verification (Reconciliation and Validation Checklist).
Prioritize reliable access to functions over decorative UI.

## Timed implementation target
F01 15 min; F02 15 min; F03 10 min; F04 10 min; Validation 10 min. Total: 60 minutes.

## Acceptance test
A passing Base build lets a user search for a member, inspect reservations, create a valid reservation, reject an invalid foreign key/status, find and update a reservation, navigate to required queries/reports, and complete the workflow without directly editing underlying tables.