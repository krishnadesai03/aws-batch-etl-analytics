# Day 7 — Code Refactor, Documentation, and Debugging

## 🎯 Objective
Refactor the codebase into a modular, production-style structure and update project documentation to clearly describe the pipeline architecture and data flow.

---

## 🔧 Refactoring Summary
The project was refactored to separate concerns and improve maintainability:

- Core logic moved into a `src/` package with reusable modules
- Database connection logic centralized in `src/db.py`
- Ingestion and transformation logic modularized for reuse and testing
- Lightweight CLI wrappers added under `scripts/`
- Repository structure cleaned to reflect production data engineering standards
- README updated to clearly explain architecture and data flow

This refactor makes the pipeline easier to test, extend, and orchestrate in later weeks.

---

## 🧪 Testing Structure
A minimal `tests/` directory was introduced with smoke tests to:
- Validate database connectivity
- Ensure core warehouse tables exist
- Catch breaking changes early during refactors

---

## 🛠️ Debugging: Ingestion & Testing Failures

### Issues Encountered
During refactoring and testing, multiple interconnected issues surfaced:

- Pandas repeatedly misidentified the PostgreSQL connection as SQLite, leading to:
  - `?` placeholder errors
  - unexpected `sqlite_master` queries
  - `Engine` / `Connection` objects missing `cursor` attributes
- SQLAlchemy connection objects were incorrectly used as context managers, causing `__enter__` errors
- Failed SQL statements left transactions in an aborted state, blocking subsequent queries
- Pytest failed to resolve imports due to missing `PYTHONPATH` configuration

---

### Resolution
These issues were resolved through a series of deliberate fixes:

- Bypassed Pandas’ SQL abstraction for ingestion and switched to **Postgres-native `COPY`** using a raw DBAPI cursor for reliable bulk loads
- Explicitly managed transactions with manual `commit()` and `rollback()` to avoid aborted states
- Executed SQL directly in tests using `engine.connect().execute(text(...))` instead of Pandas helpers
- Standardized test execution via `pytest` with correct module paths and project structure

---

## ✅ Outcome
- Ingestion is now deterministic and database-native
- Tests are reliable and free from implicit SQL abstraction bugs
- Refactored codebase is production-safe and easier to extend
- Documentation accurately reflects the system architecture and execution flow


