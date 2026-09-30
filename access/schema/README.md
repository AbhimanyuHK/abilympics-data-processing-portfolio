# Access Database Schema

This track recreates the competition-style relational database workflow in Microsoft Access.

## Core tables
- COUNTRY
- MEMBER
- TRAVEL
- AIRLINE
- SCHEDULE
- RESERVATION

## Relationship design
- COUNTRY 1:N MEMBER
- COUNTRY 1:N TRAVEL
- COUNTRY 1:N AIRLINE
- TRAVEL 1:N SCHEDULE
- AIRLINE 1:N SCHEDULE
- MEMBER 1:N RESERVATION
- SCHEDULE 1:N RESERVATION

## Design requirements
- Primary keys on every entity table
- Foreign keys enforced through Access relationships
- Appropriate required fields and data types
- Unique indexes for business identifiers where required
- Referential integrity enabled where appropriate
- Avoid storing derived values when they can be calculated safely
