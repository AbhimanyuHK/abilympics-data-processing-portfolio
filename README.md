# International Abilympics — Data Processing Portfolio

A structured preparation and portfolio repository for the **11th International Abilympics (Helsinki 2027)** skill **Data Management and Processing**.

> **Status:** Initial repository setup / preparation in progress  
> **Owner:** Abhimanyu Hk  
> **Profile:** Senior Data Engineer / AI Engineer — 9 years of professional experience

## Purpose

This repository is designed to demonstrate practical capability in database-driven data processing, with an emphasis on:

- Relational database design
- Data modelling and normalization
- SQL querying and data processing
- Data validation and integrity
- DBMS-based application development
- Forms, interfaces, and reporting
- Accuracy, reproducibility, and structured execution
- Timed practice and mock competition tasks

The portfolio deliberately keeps the competition work focused on **data management and processing fundamentals**, while professional engineering extensions may demonstrate automation and modern tooling.

## Competition Alignment

The official Helsinki 2027 skill description describes Data Management and Processing as designing and developing database-driven applications using a DBMS, including database design, queries, data-processing logic, relational databases, normalization, performance optimization, security, and scalability.

The official 2027 Technical Description is scheduled for **November 2026**, and the actual Task Assignment is scheduled for **February 2027**. Until those documents are released, this repository uses the official skill description and previous competition material only as preparation guidance.

Official reference: https://abilympics2027.com/en/skills-categories/ict/data-management-and-processing/

## Abilympics Syllabus Mapping

This table maps the repository's practical work to four core Data Management and Processing preparation areas.

| Syllabus area | Repository implementation | Evidence |
|---|---|---|
| **Schema Design** | Relational model, entities, primary/foreign keys, constraints, indexes, relationship map | `database/schema/`, `database/relationships/`, `sql/schema.sql` |
| **Relational Normalization** | 3NF-oriented design, dependency-aware table separation, PK/FK integrity and normalization exercises | `database/schema/travel-reservation-schema.md`, `practice/task-01/` |
| **SQL Query Optimization** | Saved analytical queries, joins, aggregations, filtering, duplicate detection, validation queries, and indexed PostgreSQL schema | `sql/queries/`, `sql/validation/`, `sql/schema.sql` |
| **Automated Ingestion/Reporting** | CSV ingestion workflow, dirty-data processing, validation/reconciliation, Excel reporting, DBMS reporting specifications, and reproducible processing flow | `datasets/`, `excel/`, `libreoffice-base/`, `access/`, `practice/mock-competition/` |

### Navigation

1. **Schema Design** → `database/schema/` → `database/relationships/` → `sql/schema.sql`
2. **Relational Normalization** → `database/schema/travel-reservation-schema.md` → `practice/task-01/`
3. **SQL Query Optimization** → `sql/queries/` → `sql/reports/` → `sql/validation/`
4. **Automated Ingestion/Reporting** → `datasets/` → `excel/` → `libreoffice-base/` → `access/`
5. **Timed Demonstration** → `practice/mock-competition/`

> **Scope note:** “Automated Ingestion/Reporting” represents the repository's engineering-oriented preparation workflow. The competition-focused core remains DBMS design, data processing, queries, interfaces, validation, and reporting. The repository is independently developed practice material, not an official 2027 task.

## Repository Roadmap

### Phase 1 — Foundation
- [x] Repository created
- [x] Initial structure
- [ ] Competition reference notes
- [ ] Database design baseline
- [ ] Sample datasets

### Phase 2 — Core Data Processing
- [ ] Relational schema
- [ ] Normalization exercises
- [ ] SQL query library
- [ ] Data-quality and validation exercises
- [ ] Reporting queries

### Phase 3 — Application Skills
- [ ] DBMS application
- [ ] User-facing forms
- [ ] Administrative interface
- [ ] Reports
- [ ] Error handling and validation

### Phase 4 — Timed Practice
- [ ] Practice Task 01
- [ ] Practice Task 02
- [ ] Practice Task 03
- [ ] Full mock competition
- [ ] Timed execution log
- [ ] Post-task review

### Phase 5 — Competition-Ready Portfolio
- [ ] Competition-oriented database project
- [ ] Evidence screenshots
- [ ] Final documentation
- [ ] Performance and accuracy checklist
- [ ] Final mock assessments

## Repository Structure

```text
abilympics-data-processing-portfolio/
│
├── README.md
├── docs/
│   ├── competition-overview.md
│   ├── preparation-plan.md
│   └── scoring-strategy.md
│
├── database/
│   ├── schema/
│   ├── relationships/
│   └── sample-data/
│
├── sql/
│   ├── queries/
│   ├── reports/
│   └── validation/
│
├── excel/
│   ├── input/
│   ├── processed/
│   └── reports/
│
├── access/
│   ├── database/
│   ├── queries/
│   ├── forms/
│   └── reports/
│
├── practice/
│   ├── task-01/
│   ├── task-02/
│   ├── task-03/
│   └── mock-competition/
│
├── datasets/
├── screenshots/
└── portfolio/
```

## Main Portfolio Project

The initial portfolio project will be an independently designed **Travel Reservation & Data Management System**.

It will provide a realistic environment for practising:

1. Relational data modelling
2. Primary and foreign keys
3. Normalization
4. Referential integrity
5. Data cleaning and validation
6. SQL queries
7. Aggregations and reporting
8. Reservation/business-rule processing
9. User and administrator workflows
10. Timed database development

The project is inspired by the type of database-processing work seen in previous competitions, but it will be an independently developed practice system and **not a reproduction of any official 2027 task**.

## Competition Track vs Engineering Track

### Competition Track
Focus on the skills most directly relevant to the competition environment:

- DBMS
- Relational design
- SQL
- Queries
- Forms
- Reports
- Validation
- Accuracy
- Speed
- Clear documentation

### Engineering Track
Where useful, the portfolio may additionally include:

- Python
- PostgreSQL
- Automated validation
- Test cases
- Docker
- API integration
- Data-quality automation
- Reproducible execution

These extensions are secondary to the core competition skills.

## Quality Principles

Every exercise in this repository should aim for:

**Correctness → Validation → Usability → Reproducibility → Speed**

A solution that works but contains incorrect relationships, inconsistent data, weak validation, or unexplained assumptions is not considered complete.

## Important Note

This is a personal preparation and portfolio repository. It is **not an official Abilympics repository, submission, or endorsement**.

Competition requirements may change when the official 2027 Technical Description and Task Assignment are released. This repository will be updated as official information becomes available.

## Author

**Abhimanyu Hk**

Senior Data Engineer / AI Engineer

GitHub: https://github.com/AbhimanyuHK

---

*Built for disciplined preparation, measurable practice, and a strong evidence-based data processing portfolio.*

## Portfolio Readiness

The repository is ready to share as a **practice/portfolio repository** now. It demonstrates the intended workflow through SQL, datasets, Excel processing, validation, reporting, timed mock tasks, and detailed Access/LibreOffice Base implementation specifications.

Remaining items are execution evidence rather than missing design: create and test the `.accdb`/`.odb` locally, complete one full 180-minute mock run, and add screenshots/results. Present these as practice evidence, not official competition deliverables.
