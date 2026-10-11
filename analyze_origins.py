import csv
import json
from pathlib import Path

root = Path(__file__).resolve().parent

# Находим файл из последней успешной загрузки.
checks = json.loads(
    (root / "checks.json").read_text(encoding="utf-8")
)
source = next(
    item for item in checks
    if Path(item["raw_file"]).name.startswith("origins_")
)
data = json.loads(
    (root / source["raw_file"]).read_text(encoding="utf-8")
)

rows = sorted(
    data["items"],
    key=lambda row: (row["coo_iso"], row["year"]),
)

output = root / "data" / "processed"
output.mkdir(parents=True, exist_ok=True)
csv_file = output / "origins.csv"

# Для каждой страны отдельно запоминаем предыдущий год.
previous = {}

with csv_file.open("w", newline="", encoding="utf-8-sig") as file:
    writer = csv.writer(file)
    writer.writerow([
        "year", "origin", "refugees",
        "change_people", "change_percent", "oip"
    ])

    print("Страна | Год | Беженцы | Изменение | %")

    for row in rows:
        country = row["coo_iso"]
        year = int(row["year"])
        current = int(row["refugees"])
        raw_oip = row.get("oip")
        oip = None if raw_oip in (None, "", "-") else int(raw_oip)

        change = None
        percent = None
        prior = previous.get(country)

        if prior is not None and prior[0] == year - 1:
            change = current - prior[1]
            if prior[1] != 0:
                percent = round(change / prior[1] * 100, 2)

        writer.writerow([
            year, country, current, change, percent, oip
        ])

        change_text = "—" if change is None else f"{change:+,}"
        percent_text = "—" if percent is None else f"{percent:+.2f}%"
        print(
            f"{country} | {year} | {current:,} | "
            f"{change_text} | {percent_text}"
        )

        previous[country] = (year, current)

print(f"\nТаблица сохранена: {csv_file}")