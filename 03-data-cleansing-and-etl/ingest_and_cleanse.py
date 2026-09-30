#!/usr/bin/env python3
"""Load dirty procurement CSV data into a normalized SQLite database."""

from __future__ import annotations

import argparse
import csv
import logging
import re
import sqlite3
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any

LOGGER = logging.getLogger("procurement_ingestion")

DATE_FORMATS = (
    "%d/%m/%Y",
    "%Y-%m-%d",
    "%d %b %Y",
    "%Y/%m/%d",
    "%d-%m-%Y",
)
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
ITEM_RE = re.compile(r"^\s*([A-Za-z0-9-]+)\s*-\s*(.+?)\s*$")
PO_RE = re.compile(r"^\s*(PO-[A-Za-z0-9-]+)\s*/\s*line\s*(\d+)\s*$", re.I)
SNAPSHOT_RE = re.compile(r"Stock\s*=\s*(-?\d+)\s*;\s*Reorder\s*=\s*(-?\d+)", re.I)
PHONE_RE = re.compile(r"\d+")


def clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    value = re.sub(r"\s+", " ", value.strip())
    return value or None


def normalize_email(value: str | None) -> str | None:
    value = clean_text(value)
    if not value:
        return None
    value = re.sub(r"\s+", "", value).lower()
    if not EMAIL_RE.fullmatch(value):
        raise ValueError(f"invalid email: {value}")
    return value


def normalize_phone(value: str | None) -> str | None:
    value = clean_text(value)
    if not value:
        return None

    digits = "".join(PHONE_RE.findall(value))

    if len(digits) == 10:
        return "+91" + digits
    if len(digits) == 11 and digits.startswith("0"):
        return "+91" + digits[1:]
    if len(digits) == 12 and digits.startswith("91"):
        return "+" + digits

    raise ValueError(f"invalid phone: {value}")


def parse_date(value: str | None) -> str | None:
    value = clean_text(value)
    if not value:
        return None

    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(value, fmt).date().isoformat()
        except ValueError:
            continue

    raise ValueError(f"invalid date: {value}")


def parse_positive_int(value: str | None, field: str) -> int:
    value = clean_text(value)
    if not value:
        raise ValueError(f"{field} is null/blank")

    if not re.fullmatch(r"[+]?\d[\d,]*(?:\s*[A-Za-z]+)?", value):
        raise ValueError(f"invalid {field}: {value}")

    digits = re.sub(r"[^0-9]", "", value)
    result = int(digits)

    if result <= 0:
        raise ValueError(f"{field} must be greater than zero: {value}")

    return result


def parse_price(value: str | None) -> float:
    value = clean_text(value)
    if not value:
        raise ValueError("unit_price is null/blank")

    value = re.sub(r"^(INR|Rs\.?|₹)\s*", "", value, flags=re.I)
    value = value.replace(",", "")

    try:
        result = float(value)
    except ValueError as exc:
        raise ValueError(f"invalid unit_price: {value}") from exc

    if result < 0:
        raise ValueError(f"unit_price must be non-negative: {value}")

    return round(result, 2)


def parse_supplier(details: str) -> tuple[str, str | None, str | None]:
    parts = [clean_text(part) for part in (details or "").split("|")]

    if len(parts) != 3 or not all(parts):
        raise ValueError(
            "supplier_details must contain supplier, contact, and email"
        )

    supplier_name = parts[0]
    contact_name = parts[1]
    email = normalize_email(parts[2])

    return re.sub(r"\s+", " ", supplier_name), contact_name, email


def parse_item(details: str) -> tuple[str, str]:
    match = ITEM_RE.fullmatch(details or "")
    if not match:
        raise ValueError(f"invalid item_details: {details}")
    return match.group(1).upper(), clean_text(match.group(2)) or ""


def parse_order(details: str) -> tuple[str, int]:
    match = PO_RE.fullmatch(details or "")
    if not match:
        raise ValueError(f"invalid order_details: {details}")
    return match.group(1).upper(), int(match.group(2))


def parse_snapshot(value: str) -> tuple[int, int]:
    match = SNAPSHOT_RE.fullmatch(clean_text(value) or "")
    if not match:
        raise ValueError(f"invalid inventory_snapshot: {value}")

    stock = int(match.group(1))
    reorder = int(match.group(2))

    if stock < 0 or reorder < 0:
        raise ValueError("stock and reorder levels must be non-negative")

    return stock, reorder


def parse_contact(value: str) -> tuple[str | None, str | None]:
    value = clean_text(value)
    if not value:
        return None, None

    email_match = re.search(
        r"[A-Za-z0-9._%+\-\s]+@[A-Za-z0-9.\-\s]+\.[A-Za-z]{2,}",
        value,
    )

    if not email_match:
        raise ValueError("contact does not contain a valid email")

    email = normalize_email(email_match.group(0))
    phone_part = value[email_match.end():]
    phone = normalize_phone(phone_part)

    return email, phone


def init_db(connection: sqlite3.Connection, ddl_path: Path) -> None:
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(ddl_path.read_text(encoding="utf-8"))


def get_or_create_category(connection: sqlite3.Connection, name: str) -> int:
    name = clean_text(name) or "Uncategorized"

    row = connection.execute(
        "SELECT category_id FROM categories WHERE lower(category_name)=lower(?)",
        (name,),
    ).fetchone()

    if row:
        return int(row[0])

    connection.execute(
        """
        INSERT INTO categories(category_id, category_name)
        VALUES ((SELECT COALESCE(MAX(category_id),0)+1 FROM categories), ?)
        """,
        (name,),
    )

    return int(
        connection.execute(
            "SELECT category_id FROM categories WHERE lower(category_name)=lower(?)",
            (name,),
        ).fetchone()[0]
    )


def get_or_create_supplier(
    connection: sqlite3.Connection,
    supplier_name: str,
    contact_name: str | None,
    email: str | None,
    phone: str | None,
) -> int:
    canonical_name = re.sub(r"\s+", " ", supplier_name).strip()
    key = canonical_name.casefold()

    row = connection.execute(
        "SELECT supplier_id FROM suppliers WHERE lower(supplier_name)=?",
        (key,),
    ).fetchone()

    if row:
        supplier_id = int(row[0])
        connection.execute(
            """
            UPDATE suppliers
            SET contact_name=COALESCE(?,contact_name),
                email=COALESCE(?,email),
                phone=COALESCE(?,phone)
            WHERE supplier_id=?
            """,
            (contact_name, email, phone, supplier_id),
        )
        return supplier_id

    connection.execute(
        """
        INSERT INTO suppliers(
            supplier_id,supplier_name,contact_name,email,phone,active
        )
        VALUES (
            (SELECT COALESCE(MAX(supplier_id),0)+1 FROM suppliers),
            ?, ?, ?, ?, 1
        )
        """,
        (canonical_name, contact_name, email, phone),
    )

    return int(
        connection.execute(
            "SELECT supplier_id FROM suppliers WHERE lower(supplier_name)=?",
            (key,),
        ).fetchone()[0]
    )


def get_or_create_item(
    connection: sqlite3.Connection,
    item_code: str,
    item_name: str,
    category_id: int,
    stock: int,
    reorder: int,
) -> int:
    row = connection.execute(
        "SELECT item_id FROM inventory_items WHERE item_code=?",
        (item_code,),
    ).fetchone()

    if row:
        item_id = int(row[0])
        connection.execute(
            """
            UPDATE inventory_items
            SET current_stock=?, reorder_level=?
            WHERE item_id=?
            """,
            (stock, reorder, item_id),
        )
        return item_id

    connection.execute(
        """
        INSERT INTO inventory_items(
            item_id,item_code,item_name,category_id,reorder_level,
            current_stock,standard_unit,active
        )
        VALUES (
            (SELECT COALESCE(MAX(item_id),0)+1 FROM inventory_items),
            ?, ?, ?, ?, ?, 'EA', 1
        )
        """,
        (item_code, item_name, category_id, reorder, stock),
    )

    return int(
        connection.execute(
            "SELECT item_id FROM inventory_items WHERE item_code=?",
            (item_code,),
        ).fetchone()[0]
    )


def get_or_create_po(
    connection: sqlite3.Connection,
    po_number: str,
    supplier_id: int,
    order_date: str,
) -> int:
    row = connection.execute(
        """
        SELECT po_id, supplier_id, order_date
        FROM purchase_orders
        WHERE po_number=?
        """,
        (po_number,),
    ).fetchone()

    if row:
        if int(row[1]) != supplier_id or row[2] != order_date:
            raise ValueError(
                f"PO {po_number} has inconsistent supplier or order date"
            )
        return int(row[0])

    connection.execute(
        """
        INSERT INTO purchase_orders(
            po_id,po_number,supplier_id,order_date,currency_code,po_status
        )
        VALUES (
            (SELECT COALESCE(MAX(po_id),0)+1 FROM purchase_orders),
            ?, ?, ?, 'INR', 'OPEN'
        )
        """,
        (po_number, supplier_id, order_date),
    )

    return int(
        connection.execute(
            "SELECT po_id FROM purchase_orders WHERE po_number=?",
            (po_number,),
        ).fetchone()[0]
    )


def update_po_statuses(connection: sqlite3.Connection) -> None:
    rows = connection.execute(
        """
        SELECT
            po_id,
            COUNT(*) AS line_count,
            SUM(
                CASE WHEN actual_delivery_date IS NOT NULL
                     THEN 1 ELSE 0 END
            ) AS delivered_count
        FROM order_lines
        GROUP BY po_id
        """
    ).fetchall()

    for po_id, line_count, delivered_count in rows:
        if delivered_count == 0:
            status = "OPEN"
        elif delivered_count == line_count:
            status = "DELIVERED"
        else:
            status = "PARTIALLY_DELIVERED"

        connection.execute(
            "UPDATE purchase_orders SET po_status=? WHERE po_id=?",
            (status, po_id),
        )


def write_audit(
    connection: sqlite3.Connection,
    run_id: str,
    source_row_number: int | None,
    event_type: str,
    severity: str,
    message: str,
    raw_payload: str | None,
) -> None:
    connection.execute(
        """
        INSERT INTO audit_logs(
            audit_id,run_id,source_row_number,event_type,severity,
            message,raw_payload
        )
        VALUES (
            (SELECT COALESCE(MAX(audit_id),0)+1 FROM audit_logs),
            ?, ?, ?, ?, ?, ?
        )
        """,
        (
            run_id,
            source_row_number,
            event_type,
            severity,
            message,
            raw_payload,
        ),
    )


def load(
    raw_path: Path,
    db_path: Path,
    ddl_path: Path,
) -> dict[str, Any]:
    run_id = uuid.uuid4().hex[:12]
    stats: dict[str, Any] = {
        "read": 0,
        "accepted": 0,
        "rejected": 0,
    }

    db_path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(db_path) as connection:
        init_db(connection, ddl_path)

        with raw_path.open(
            "r",
            encoding="utf-8-sig",
            newline="",
        ) as handle:
            reader = csv.DictReader(handle)

            for row in reader:
                stats["read"] += 1
                source_row = stats["read"] + 1

                try:
                    supplier_name, contact_name, supplier_email = parse_supplier(
                        row.get("supplier_details", "")
                    )
                    contact_email, phone = parse_contact(
                        row.get("contact", "")
                    )
                    email = contact_email or supplier_email

                    item_code, item_name = parse_item(
                        row.get("item_details", "")
                    )
                    po_number, line_number = parse_order(
                        row.get("order_details", "")
                    )
                    category = clean_text(row.get("category")) or "Uncategorized"
                    quantity = parse_positive_int(
                        row.get("quantity"), "quantity"
                    )
                    unit_price = parse_price(row.get("unit_price"))
                    order_date = parse_date(row.get("order_date"))
                    expected_date = parse_date(row.get("expected_delivery"))
                    actual_date = parse_date(row.get("actual_delivery"))
                    stock, reorder = parse_snapshot(
                        row.get("inventory_snapshot", "")
                    )

                    if actual_date and actual_date < order_date:
                        raise ValueError(
                            "actual_delivery cannot precede order_date"
                        )

                    if expected_date < order_date:
                        raise ValueError(
                            "expected_delivery cannot precede order_date"
                        )

                    category_id = get_or_create_category(connection, category)
                    supplier_id = get_or_create_supplier(
                        connection,
                        supplier_name,
                        contact_name,
                        email,
                        phone,
                    )
                    item_id = get_or_create_item(
                        connection,
                        item_code,
                        item_name,
                        category_id,
                        stock,
                        reorder,
                    )
                    po_id = get_or_create_po(
                        connection,
                        po_number,
                        supplier_id,
                        order_date,
                    )

                    connection.execute(
                        """
                        INSERT INTO order_lines(
                            order_line_id,po_id,line_number,item_id,quantity,
                            unit_price,expected_delivery_date,actual_delivery_date
                        )
                        VALUES (
                            (SELECT COALESCE(MAX(order_line_id),0)+1
                             FROM order_lines),
                            ?, ?, ?, ?, ?, ?, ?
                        )
                        """,
                        (
                            po_id,
                            line_number,
                            item_id,
                            quantity,
                            unit_price,
                            expected_date,
                            actual_date,
                        ),
                    )

                    write_audit(
                        connection,
                        run_id,
                        source_row,
                        "ROW_ACCEPTED",
                        "INFO",
                        "Normalized and loaded successfully",
                        repr(dict(row)),
                    )
                    stats["accepted"] += 1

                except (ValueError, sqlite3.IntegrityError) as exc:
                    stats["rejected"] += 1
                    write_audit(
                        connection,
                        run_id,
                        source_row,
                        "ROW_REJECTED",
                        "ERROR",
                        str(exc),
                        repr(dict(row)),
                    )

        update_po_statuses(connection)

        write_audit(
            connection,
            run_id,
            None,
            "RUN_SUMMARY",
            "INFO",
            (
                f"Read={stats['read']}; "
                f"Accepted={stats['accepted']}; "
                f"Rejected={stats['rejected']}"
            ),
            None,
        )

        connection.commit()

    return {"run_id": run_id, **stats}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Ingest and cleanse procurement CSV data into SQLite."
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=(
            Path(__file__).resolve().parents[1]
            / "01-schema-normalization-3nf"
            / "raw_procurement_data.csv"
        ),
    )
    parser.add_argument(
        "--database",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "procurement.db",
    )
    parser.add_argument(
        "--ddl",
        type=Path,
        default=(
            Path(__file__).resolve().parents[1]
            / "01-schema-normalization-3nf"
            / "01_ddl_tables_constraints.sql"
        ),
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s %(message)s",
    )

    result = load(args.input, args.database, args.ddl)

    LOGGER.info(
        (
            "run_id=%s rows_read=%d rows_accepted=%d "
            "rows_rejected=%d database=%s"
        ),
        result["run_id"],
        result["read"],
        result["accepted"],
        result["rejected"],
        args.database,
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
