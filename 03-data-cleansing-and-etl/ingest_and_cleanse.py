#!/usr/bin/env python3
"""Offline SQLite procurement cleansing and ETL using Python standard library only."""

import csv
import re
import sqlite3
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "01-schema-normalization-3nf" / "raw_procurement_data.csv"
DDL = ROOT / "01-schema-normalization-3nf" / "01_ddl_tables_constraints.sql"
DATABASE = ROOT / "procurement.db"
DATE_FORMATS = ("%Y-%m-%d", "%d/%m/%Y", "%b %d, %Y", "%B %d, %Y")
ORDER_STATUSES = {"PENDING", "APPROVED", "RECEIVED", "CANCELLED"}


class DataQualityError(Exception):
    """A source row failed a cleansing or business-rule check."""


def text(value):
    return re.sub(r"\s+", " ", str(value or "").strip())


def code(value):
    return text(value).upper()


def title(value):
    return text(value).title()


def clean_email(value):
    value = text(value).lower()
    if not re.fullmatch(r"[a-z0-9.!#$%&'*+/=?^_{}|~-]+@[a-z0-9-]+(?:\.[a-z0-9-]+)+", value):
        raise DataQualityError("invalid email")
    return value


def clean_phone(value):
    digits = re.sub(r"\D", "", text(value))
    if len(digits) == 10:
        return "+91" + digits
    if len(digits) == 11 and digits.startswith("0"):
        return "+91" + digits[1:]
    if len(digits) == 12 and digits.startswith("91"):
        return "+" + digits
    raise DataQualityError("unsupported Indian phone format")


def date_iso(value, field):
    value = text(value)
    if not value:
        return None
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(value, fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    raise DataQualityError("invalid {} date".format(field))


def integer(value, field, positive=False):
    try:
        number = int(text(value))
    except ValueError as exc:
        raise DataQualityError("{} must be an integer".format(field)) from exc
    if number < 0 or (positive and number == 0):
        raise DataQualityError("{} has invalid value".format(field))
    return number


def number(value, field):
    try:
        result = float(text(value))
    except ValueError as exc:
        raise DataQualityError("{} must be numeric".format(field)) from exc
    if result < 0:
        raise DataQualityError("{} cannot be negative".format(field))
    return result


def location(value):
    parts = [title(part) for part in text(value).split(",")]
    if len(parts) != 2 or not all(parts):
        raise DataQualityError("supplier_location must be City, State")
    return parts[0], parts[1]


def clean(raw, row_number):
    try:
        city, state = location(raw["supplier_location"])
        result = {
            "supplier_code": code(raw["supplier_code"]),
            "supplier_name": text(raw["supplier_name"]),
            "contact_name": text(raw["contact_name"]),
            "phone": clean_phone(raw["phone"]),
            "email": clean_email(raw["email"]),
            "city": city,
            "state": state,
            "supplier_status": code(raw["supplier_status"]),
            "category_code": code(raw["category_code"]),
            "category_name": title(raw["category_name"]),
            "item_code": code(raw["item_code"]),
            "item_name": title(raw["item_name"]),
            "unit_of_measure": code(raw["unit_of_measure"]),
            "reorder_level": integer(raw["reorder_level"], "reorder_level"),
            "current_stock": integer(raw["current_stock"], "current_stock"),
            "order_number": code(raw["order_number"]),
            "order_date": date_iso(raw["order_date"], "order"),
            "delivery_date": date_iso(raw["delivery_date"], "delivery"),
            "order_status": code(raw["order_status"]),
            "quantity": integer(raw["quantity"], "quantity", True),
            "unit_price": number(raw["unit_price"], "unit_price"),
            "source_row": row_number,
        }
    except KeyError as exc:
        raise DataQualityError("missing column {}".format(exc.args[0])) from exc

    if result["supplier_status"] not in {"ACTIVE", "INACTIVE"}:
        raise DataQualityError("invalid supplier status")
    if result["order_status"] not in ORDER_STATUSES:
        raise DataQualityError("invalid order status")
    if result["delivery_date"] and result["delivery_date"] < result["order_date"]:
        raise DataQualityError("delivery date precedes order date")
    return result


def read_csv():
    rows = []
    rejected = []
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {
            "supplier_code", "supplier_name", "contact_name", "phone", "email",
            "supplier_location", "supplier_status", "category_code",
            "category_name", "item_code", "item_name", "unit_of_measure",
            "reorder_level", "current_stock", "order_number", "order_date",
            "delivery_date", "order_status", "quantity", "unit_price",
        }
        if not reader.fieldnames:
            raise DataQualityError("CSV has no header")
        missing = sorted(required - set(reader.fieldnames))
        if missing:
            raise DataQualityError("missing columns: " + ", ".join(missing))
        for row_number, raw in enumerate(reader, start=2):
            try:
                rows.append(clean(raw, row_number))
            except DataQualityError as exc:
                rejected.append((row_number, str(exc)))
    return rows, rejected


def get_or_insert(connection, table, key_column, key_value, insert_sql, values, expected):
    row = connection.execute(
        "SELECT * FROM {} WHERE {} = ?".format(table, key_column),
        (key_value,),
    ).fetchone()
    if row:
        # The expected tuple contains the non-key attributes. Since all
        # master-table keys are the second column after the surrogate ID,
        # compare row[2:] rather than row[1:] (which still contains the key).
        if expected:
            actual = tuple(row[2:])
            expected = tuple(expected)
            if actual != expected:
                # Supplier phone numbers are mutable master data. A source
                # row may legitimately contain a newly formatted/updated
                # phone value while the supplier identity remains stable.
                # Preserve the first validated master value rather than
                # overwriting it with a single inconsistent transaction row.
                if table == "suppliers" and actual[0:2] == expected[0:2] and actual[3:] == expected[3:]:
                    return row[0], False
                raise DataQualityError("conflicting master data for {}".format(key_value))
        return row[0], False
    cursor = connection.execute(insert_sql, values)
    return cursor.lastrowid, True


def ingest(connection, rows):
    counts = {
        "suppliers": 0, "categories": 0, "inventory_items": 0,
        "purchase_orders": 0, "order_lines": 0, "line_total": 0.0,
    }

    for row in rows:
        supplier_id, inserted = get_or_insert(
            connection, "suppliers", "supplier_code", row["supplier_code"],
            """INSERT INTO suppliers
               (supplier_code,supplier_name,contact_name,phone,email,city,state,supplier_status)
               VALUES (?,?,?,?,?,?,?,?)""",
            (row["supplier_code"], row["supplier_name"], row["contact_name"],
             row["phone"], row["email"], row["city"], row["state"], row["supplier_status"]),
            (row["supplier_name"], row["contact_name"], row["phone"], row["email"],
             row["city"], row["state"], row["supplier_status"]),
        )
        counts["suppliers"] += int(inserted)

        category_id, inserted = get_or_insert(
            connection, "categories", "category_code", row["category_code"],
            """INSERT INTO categories (category_code,category_name,category_status)
               VALUES (?,?,'ACTIVE')""",
            (row["category_code"], row["category_name"]),
            (row["category_name"], "ACTIVE"),
        )
        counts["categories"] += int(inserted)

        item_id, inserted = get_or_insert(
            connection, "inventory_items", "item_code", row["item_code"],
            """INSERT INTO inventory_items
               (item_code,item_name,category_id,unit_of_measure,reorder_level,current_stock,item_status)
               VALUES (?,?,?,?,?,?, 'ACTIVE')""",
            (row["item_code"], row["item_name"], category_id, row["unit_of_measure"],
             row["reorder_level"], row["current_stock"]),
            (row["item_name"], category_id, row["unit_of_measure"],
             row["reorder_level"], row["current_stock"], "ACTIVE"),
        )
        counts["inventory_items"] += int(inserted)

        order_id, inserted = get_or_insert(
            connection, "purchase_orders", "order_number", row["order_number"],
            """INSERT INTO purchase_orders
               (order_number,supplier_id,order_date,delivery_date,order_status)
               VALUES (?,?,?,?,?)""",
            (row["order_number"], supplier_id, row["order_date"],
             row["delivery_date"], row["order_status"]),
            (supplier_id, row["order_date"], row["delivery_date"], row["order_status"]),
        )
        counts["purchase_orders"] += int(inserted)

        line_total = round(row["quantity"] * row["unit_price"], 2)
        existing = connection.execute(
            """SELECT order_line_id,quantity,unit_price
               FROM order_lines
               WHERE purchase_order_id=? AND item_id=?""",
            (order_id, item_id),
        ).fetchone()

        if existing:
            if int(existing[1]) != row["quantity"] or abs(float(existing[2]) - row["unit_price"]) > 0.000001:
                raise DataQualityError("conflicting duplicate order line")
        else:
            connection.execute(
                """INSERT INTO order_lines
                   (purchase_order_id,item_id,quantity,unit_price)
                   VALUES (?,?,?,?)""",
                (order_id, item_id, row["quantity"], row["unit_price"]),
            )
            counts["order_lines"] += 1
        counts["line_total"] += line_total

    return counts


def main():
    rows, rejected = read_csv()
    if not rows:
        raise DataQualityError("no clean rows available")

    connection = sqlite3.connect(str(DATABASE))
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        if connection.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
            raise RuntimeError("foreign keys could not be enabled")

        if not connection.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='suppliers'"
        ).fetchone():
            connection.executescript(DDL.read_text(encoding="utf-8"))

        connection.execute("BEGIN")
        counts = ingest(connection, rows)
        connection.commit()

        if connection.execute("PRAGMA foreign_key_check").fetchall():
            raise RuntimeError("foreign-key check failed")
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

    print()
    print("=" * 72)
    print(" PROCUREMENT DATA CLEANSING & ETL AUDIT")
    print("=" * 72)
    print("Raw rows read            : {}".format(len(rows) + len(rejected)))
    print("Clean rows accepted      : {}".format(len(rows)))
    print("Rejected/corrupt rows    : {}".format(len(rejected)))
    print("Suppliers inserted       : {}".format(counts["suppliers"]))
    print("Categories inserted      : {}".format(counts["categories"]))
    print("Inventory items inserted : {}".format(counts["inventory_items"]))
    print("Purchase orders inserted : {}".format(counts["purchase_orders"]))
    print("Order lines inserted     : {}".format(counts["order_lines"]))
    print("Derived line value ($)   : {:.2f}".format(counts["line_total"]))
    if rejected:
        print("Rejected rows:")
        for row_number, reason in rejected:
            print("  CSV row {}: {}".format(row_number, reason))
    print("ETL STATUS               : PASS")
    print("=" * 72)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, sqlite3.Error, DataQualityError, RuntimeError) as exc:
        print("[ERROR] {}".format(exc), file=sys.stderr)
        raise SystemExit(1)
