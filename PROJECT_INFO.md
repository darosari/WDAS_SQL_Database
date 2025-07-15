# Project Information: WDAS SQL Database Project

## Project Title
**Whale Dive Annotation System (WDAS): A Relational Database for Marine Behavior Research**

## Course
IST 659: Data Administration Concepts and Database Management

## Team Members
Dawryn Rosario, Gil Raitses, Ethan Qui

## Summary of Work
The Whale Dive Annotation System (WDAS) was developed as a fully normalized relational database to manage marine behavioral research data. The project simulates a scientific computing workflow for managing biologging, annotations, and classification results related to humpback whale dives. 

Built with PostgreSQL and visualized using ERD tools, this system emphasizes data traceability, reproducibility, and version control—core principles in behavioral ecology. Our work included schema design (up to 3NF), SQL DDL scripts, Jupyter-based data walkthroughs, and HTML-based UI mockups for dataset ingestion and analysis.

## What I'm Most Proud Of
I'm most proud of our database architecture's ability to simulate a real-world ecological data pipeline. From tracking versioned annotations to linking machine learning classifications with datasets, this project displays a full ecosystem of data operations with integrity and scalability. Collaborating with teammates on normalization, diagramming, and SQL query logic was also a rewarding challenge.

## Project Contents

- `diagrams/`: Entity-Relationship Diagrams for conceptual and logical schema
  - `dataModel_Conceptual.jpeg`  
  - `dataModel_Logical.jpeg`  
  - `README.md`  

- `docs/`: Supporting documentation and research whitepaper
  - `Whitepaper.pdf`  
  - `README.md`  

- `notebooks/`: Jupyter walkthrough for loading, querying, and interpreting WDAS data
  - `WDAS_Walkthrough.ipynb`  
  - `README.md`  

- `schema/`: SQL scripts to create all WDAS database tables
  - `ddl_wdas_schema.sql`  
  - `README.md`  

- `ui-prototypes/`: HTML-based user interface mockups for dataset import and summary view
  - `form_importManagerUI.html`  
  - `form_datasetSummaryViewUI.html`  
  - `README.md`  

- `README.md`: Main documentation describing project goals, structure, and instructions

## Required Software
- PostgreSQL or SQLite
- Jupyter Notebook
- Python 3.x
- Compatible browser (for UI HTML previews)
- Recommended tools:
  - dbdiagram.io or Lucidchart for ERD
  - pgAdmin (if using PostgreSQL)

---

_Last updated: July 2025_