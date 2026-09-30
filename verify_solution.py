#!/usr/bin/env python3
"""Offline end-to-end verifier for the Abilympics ICT portfolio."""

import os
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB = ROOT / "procurement.db"
DDL = ROOT / "01-schema-normalization-3nf" / "01_ddl_tables_constraints.sql"
ETL = ROOT / "03-data-cleansing-and-etl" / "ingest_and_cleanse.py"
ANALYTICAL = ROOT / "02-advanced-sql-processing" / "02_complex_analytical_queries.sql"
WINDOW = ROOT / "02-advanced-sql-processing" / "03_window_and_aggregations.sql"
REPORT = ROOT / "04-reporting-and-business-intelligence" / "executive_summary_report.sql"


GREEN = "\033[92m"
RESET = "\033[0m"


class VerificationError(Exception):
    """Raised when an evaluator-facing verification check fails."""


def execute_sql_script(connection, path):
    """Execute every complete SQL statement and retain SELECT result sets."""
    statements = []
    buffer = ""

    for line in path.read_text(encoding="utf-8").splitlines(True):
        buffer += line
        if sqlite3.complete_statement(buffer):
            statement = buffer.strip()
            buffer = ""
            if statement:
                statements.append(statement)

    if buffer.strip():
        raise VerificationError("unterminated SQL in {}".format(path))

    results = []
    for statement in statements:
        cursor = connection.execute(statement)
        if cursor.description:
            results.append(
                {
                    "columns": [column[0] for column in cursor.description],
                    "rows": cursor.fetchall(),
                }
            )
    return results


def run_etl():
    """Load the ETL module from disk and execute its public main() function."""
    namespace = {"__name__": "abilympics_ingest_module"}
    source = ETL.read_text(encoding="utf-8")
    exec(compile(source, str(ETL), "exec"), namespace)
    status = namespace["main"]()
    if status != 0:
        raise VerificationError("ingest_and_cleanse.py returned {}".format(status))


def scalar(connection, statement):
    return connection.execute(statement).fetchone()[0]


def assert_schema(connection):
    expected = {
        "suppliers", "categories", "inventory_items",
        "purchase_orders", "order_lines"
    }
    actual = {
        row[0]
        for row in connection.execute(
            "SELECT name FROM sqlite_master "
            "WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        )
    }

    if actual != expected:
        raise VerificationError("unexpected tables: {}".format(sorted(actual)))

    if scalar(connection, "PRAGMA foreign_keys") != 1:
        raise VerificationError("PRAGMA foreign_keys is not enabled")


def assert_constraints(connection):
    """Prove that FK and CHECK rules reject invalid data."""
    try:
        connection.execute(
            """
            INSERT INTO purchase_orders
            (order_number, supplier_id, order_date, delivery_date, order_status)
            VALUES ('VERIFY_BAD_FK', 999999, '2026-04-20', NULL, 'PENDING')
            """
        )
        connection.rollback()
        raise VerificationError("illegal foreign key was accepted")
    except sqlite3.IntegrityError:
        connection.rollback()

    try:
        connection.execute(
            """
            INSERT INTO order_lines
            (purchase_order_id, item_id, quantity, unit_price)
            VALUES (1, 1, 1, -1.00)
            """
        )
        connection.rollback()
        raise VerificationError("negative unit price was accepted")
    except sqlite3.IntegrityError:
        connection.rollback()

    expected_counts = {
        "suppliers": 5,
        "categories": 5,
        "inventory_items": 11,
        "purchase_orders": 13,
        "order_lines": 20,
    }

    for table, expected in expected_counts.items():
        actual = scalar(connection, "SELECT COUNT(*) FROM " + table)
        if actual != expected:
            raise VerificationError(
                "{} count: expected {}, got {}".format(table, expected, actual)
            )

    if connection.execute("PRAGMA foreign_key_check").fetchall():
        raise VerificationError("foreign_key_check returned violations")


def assert_result_sets(results, minimum_rows, label):
    if not results:
        raise VerificationError("{} produced no SELECT result".format(label))

    for index, result in enumerate(results, start=1):
        if len(result["rows"]) < minimum_rows:
            raise VerificationError(
                "{} query {} returned {} rows".format(
                    label, index, len(result["rows"])
                )
            )


def assert_executive_report(result):
    """Check the final report against the normalized dataset's exact KPIs."""
    expected = [
        ("SUP002", "Vertex Tools & Hardware", 3, 80760.0, 1, 2, 33.33, 100.0, 12.0),
        ("SUP004", "Northstar Components", 2, 80300.0, 1, 1, 50.0, 100.0, 11.0),
        ("SUP005", "Prime Industrial Packaging", 2, 39700.0, 1, 1, 50.0, 100.0, 9.0),
        ("SUP001", "Acme Industrial Supplies", 3, 27790.0, 2, 1, 66.67, 100.0, 7.0),
        ("SUP003", "GreenField Office Mart", 3, 26310.0, 2, 1, 66.67, 100.0, 7.0),
    ]

    if len(result["rows"]) != len(expected):
        raise VerificationError("executive report row count mismatch")

    for actual, target in zip(result["rows"], expected):
        actual = list(actual)
        for index, value in enumerate(target):
            if isinstance(value, float):
                if abs(float(actual[index]) - value) > 0.01:
                    raise VerificationError(
                        "executive report numeric mismatch at column {}".format(index)
                    )
            elif actual[index] != value:
                raise VerificationError(
                    "executive report mismatch: expected {}, got {}".format(
                        target, actual
                    )
                )


def main():
    required = [DDL, ETL, ANALYTICAL, WINDOW, REPORT]
    missing = [
        str(path.relative_to(ROOT))
        for path in required
        if not path.exists()
    ]
    if missing:
        raise VerificationError(
            "missing required files: {}".format(", ".join(missing))
        )

    if DB.exists():
        DB.unlink()

    print("=" * 78)
    print(" ABILYMpics ICT - DATA MANAGEMENT & PROCESSING VERIFICATION")
    print("=" * 78)
    print()

    connection = sqlite3.connect(str(DB))
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(DDL.read_text(encoding="utf-8"))
        connection.commit()
    finally:
        connection.close()

    run_etl()

    connection = sqlite3.connect(str(DB))
    try:
        connection.execute("PRAGMA foreign_keys = ON")

        assert_schema(connection)
        print(GREEN + "[✓] SQLite schema and foreign-key enforcement" + RESET)

        assert_constraints(connection)
        print(GREEN + "[✓] PK/FK/CHECK integrity tests" + RESET)

        analytical_results = execute_sql_script(connection, ANALYTICAL)
        assert_result_sets(analytical_results, 1, "Complex analytical SQL")
        print(
            GREEN + "[✓] Complex analytical SQL: {} result sets".format(
                len(analytical_results)
            ) + RESET
        )

        window_results = execute_sql_script(connection, WINDOW)
        assert_result_sets(window_results, 1, "Window SQL")
        print(
            GREEN + "[✓] Window/aggregation SQL: {} result sets".format(
                len(window_results)
            ) + RESET
        )

        report_results = execute_sql_script(connection, REPORT)
        assert_result_sets(report_results, 5, "Executive report")
        assert_executive_report(report_results[-1])
        print(
            GREEN + "[✓] Executive report: {} supplier rows".format(
                len(report_results[-1]["rows"])
            ) + RESET
        )

        status_counts = {
            "RECEIVED": scalar(
                connection,
                "SELECT COUNT(*) FROM purchase_orders WHERE order_status='RECEIVED'",
            ),
            "CANCELLED": scalar(
                connection,
                "SELECT COUNT(*) FROM purchase_orders WHERE order_status='CANCELLED'",
            ),
            "OPEN": scalar(
                connection,
                """
                SELECT COUNT(*) FROM purchase_orders
                WHERE order_status IN ('PENDING','APPROVED')
                """,
            ),
        }

        if status_counts != {"RECEIVED": 7, "CANCELLED": 1, "OPEN": 5}:
            raise VerificationError(
                "status distribution mismatch: {}".format(status_counts)
            )

        print(GREEN + "[✓] Purchase-order lifecycle distribution" + RESET)
        print()
        print("-" * 78)
        print(" TEST SUITE SUMMARY")
        print("-" * 78)
        print(GREEN + "[✓] 20 raw procurement rows processed" + RESET)
        print(GREEN + "[✓] 5 suppliers / 5 categories / 11 inventory items" + RESET)
        print(GREEN + "[✓] 13 purchase orders / 20 order lines" + RESET)
        print(GREEN + "[✓] Referential integrity enforced" + RESET)
        print(GREEN + "[✓] Negative-price CHECK rejected" + RESET)
        print(GREEN + "[✓] Illegal-FK insertion rejected" + RESET)
        print(GREEN + "[✓] Analytical SQL executed" + RESET)
        print(GREEN + "[✓] Window SQL executed" + RESET)
        print(GREEN + "[✓] Executive report matched expected KPIs" + RESET)
        print("-" * 78)
        print(" STATUS: 100% OPERATIONAL")
        print("=" * 78)
        return 0
    finally:
        connection.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, sqlite3.Error, VerificationError) as exc:
        print("[FAIL] VERIFICATION FAILED: {}".format(exc), file=sys.stderr)
        raise SystemExit(1)
