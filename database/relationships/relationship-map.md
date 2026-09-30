# Relationship Map

COUNTRY
  ├── MEMBER
  ├── TRAVEL ── SCHEDULE ── AIRLINE
  └── AIRLINE

MEMBER ── RESERVATION ── SCHEDULE

| Parent | Child | Relationship |
|---|---|---|
| COUNTRY | MEMBER | 1:N |
| COUNTRY | TRAVEL | 1:N |
| COUNTRY | AIRLINE | 1:N |
| TRAVEL | SCHEDULE | 1:N |
| AIRLINE | SCHEDULE | 1:N |
| MEMBER | RESERVATION | 1:N |
| SCHEDULE | RESERVATION | 1:N |

Use this as the relationship verification checklist before implementing the database in a DBMS.
