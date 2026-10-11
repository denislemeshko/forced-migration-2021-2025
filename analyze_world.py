import json
from pathlib import Path

root = Path(__file__).resolve().parent

checks = json.loads(
    (root / "checks.json").read_text(encoding="utf-8")
)
source = next(
    item for item in checks
    if Path(item["raw_file"]).name.startswith("world_")
)
data = json.loads(
    (root / source["raw_file"]).read_text(encoding="utf-8")
)

rows = sorted(data["items"], key=lambda row: row["year"])

print("Год | Беженцы под мандатом UNHCR")
for row in rows:
    print(f"{row['year']} | {row['refugees']:,}")

import csv

output = root / "data" / "processed"
output.mkdir(parents=True, exist_ok=True)
csv_file = output / "world.csv"

with csv_file.open("w", newline="", encoding="utf-8-sig") as file:
    writer = csv.writer(file)
    writer.writerow(["year", "refugees"])

    for row in rows:
        writer.writerow([row["year"], row["refugees"]])

print(f"Таблица сохранена: {csv_file}")