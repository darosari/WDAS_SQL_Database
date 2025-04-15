# WDAS SQL Database Project
Normalized SQL database project with schema design, ERD, and advanced queries.

## Overview
This project demonstrates a fully normalized SQL database built for the fictional organization *WDAS*_(Whale Data Analytical Systems)_. The goal was to create a clean and scalable database system with clear entity relationships, optimized queries, and data integrity.

## Tools & Technologies
- SQL (PostgreSQL / MySQL / SQLite)
- Entity-Relationship Diagram (ERD)
- Excel (for initial data structure and import)
- DB design principles (1NF to 3NF)

## Features
- Designed a normalized database schema up to 3NF
- Developed an Entity-Relationship Diagram (ERD)
- Created SQL tables with primary/foreign keys and constraints
- Populated tables using sample data and bulk inserts
- Built advanced SQL queries including:
  - Multi-table JOINs
  - Aggregations and subqueries
  - Filtering with WHERE, CASE statements
  - Reporting with GROUP BY, HAVING, and ORDER BY

## Entity-Relationship Diagram
*Insert ERD image here once uploaded — place in a `/diagrams` folder*

## Example SQL Query
```sql
-- Retrieve employees and their departments where salary > average
SELECT e.name, d.department_name, e.salary
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE e.salary > (
    SELECT AVG(salary)
    FROM employees
);

/wdas-sql-database
├── schema/          # SQL scripts for table creation
├── data/            # Sample data files or CSVs
├── queries/         # Custom queries for reporting
├── diagrams/        # ERD image or source file
└── README.md
