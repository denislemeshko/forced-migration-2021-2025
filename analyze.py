import json
from pathlib import Path

# Ищем исходные данные рядом с этим скриптом.
root = Path(__file__).resolve().parent
checks = json.loads(
    (root / "checks.json").read_text(encoding="utf-8")
)

source = next(
    item for item in checks
    if Path(item["raw_file"]).name.startswith("ukraine_germany_")
)

file = root / source["raw_file"]
data = json.loads(file.read_text(encoding="utf-8"))
rows = sorted(data["items"], key=lambda row: row["year"])

print("Беженцы из Украины в Германии на конец года")
for row in rows:
    print(f"{row['year']}: {row['refugees']:,}")

# Выбираем записи по году.
by_year = {row["year"]: row["refugees"] for row in rows}
previous = by_year[2024]
current = by_year[2025]

change = current - previous
percent = change / previous * 100

print(f"\nИзменение за 2024–2025: {change:+,} человек")
print(f"Изменение в процентах: {percent:+.2f}%")
print("Это изменение численности, а не число новых перемещений.")

print("\nГод | Численность | Изменение, чел. | Изменение, %")
previous = None

for row in rows:
    current = row["refugees"]

    if previous is None:
        print(f"{row['year']} | {current:,} | — | —")
    else:
        change = current - previous
        percent = change / previous * 100 if previous != 0 else None
        percent_text = f"{percent:+.2f}%" if percent is not None else "—"
        print(f"{row['year']} | {current:,} | {change:+,} | {percent_text}")

    previous = current

import csv

# Создаём папку для обработанных данных.
output = Path(__file__).resolve().parent / "data" / "processed"
output.mkdir(parents=True, exist_ok=True)

csv_file = output / "ukraine_germany.csv"

with csv_file.open("w", newline="", encoding="utf-8-sig") as file:
    writer = csv.writer(file)
    writer.writerow([
        "year", "origin", "asylum", "refugees",
        "change_people", "change_percent"
    ])

    previous = None

    for row in rows:
        current = row["refugees"]
        change = None if previous is None else current - previous
        percent = (
            change / previous * 100
            if previous is not None and previous != 0
            else None
        )

        writer.writerow([
            row["year"],
            row["coo_iso"],
            row["coa_iso"],
            current,
            change,
            round(percent, 2) if percent is not None else None,
        ])

        previous = current

print(f"\nТаблица сохранена: {csv_file}")