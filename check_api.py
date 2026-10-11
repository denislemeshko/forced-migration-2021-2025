"""Первый шаг: небольшие выборки UNHCR. Python 3.11+, без зависимостей."""
import hashlib
import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
RAW = ROOT / 'data' / 'raw'
BASE = 'https://api.unhcr.org/population/v1/'
YEARS = set(range(2021, 2026))

def fetch(name, endpoint, params):
    url = BASE + endpoint + '/?' + urlencode(params)
    with urlopen(Request(url, headers={'Accept': 'application/json'}), timeout=45) as response:
        body = response.read()
        status = response.status
    data = json.loads(body)
    if not isinstance(data.get('items'), list):
        raise ValueError('Нет массива items')
    if data.get('maxPages') != 1:
        raise ValueError('Выборка требует пагинации; этот учебный скрипт принимает одну страницу')
    RAW.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256(body).hexdigest()
    # Сохраняем исходные байты; одинаковый ответ не создаёт копий.
    path = RAW / f'{name}_{digest[:16]}.json'
    if not path.exists():
        path.write_bytes(body)
    return data, {'url': url, 'http_status': status,
                  'retrieved_at_utc': datetime.now(timezone.utc).isoformat(),
                  'sha256': digest, 'raw_file': str(path.relative_to(ROOT)),
                  'rows': len(data['items'])}

def main():
    logging.basicConfig(filename=ROOT / 'errors.log', level=logging.ERROR)
    common = {'yearFrom': 2021, 'yearTo': 2025, 'limit': 100}
    queries = [
        ('world', 'population', common),
        ('origins', 'population', dict(common, coo='UKR,SYR,AFG', cf_type='ISO')),
        ('ukraine_germany', 'population', dict(common, coo='UKR', coa='DEU', cf_type='ISO')),
    ]
    checks = []
    for name, endpoint, params in queries:
        data, meta = fetch(name, endpoint, params)
        items = data['items']
        actual_years = {int(row['year']) for row in items}
        keys = [(row['year'], row['coo_iso'], row['coa_iso']) for row in items]
        expected_rows = 15 if name == 'origins' else 5
        if actual_years != YEARS or len(keys) != len(set(keys)) or len(items) != expected_rows:
            raise ValueError(f'{name}: неполные годы, дубликаты или неожиданное число строк')
        if name == 'origins':
            expected = {(year, country) for year in YEARS for country in ('UKR','SYR','AFG')}
            if {(r['year'],r['coo_iso']) for r in items} != expected:
                raise ValueError('Не все пары год–страна получены')
        if name == 'ukraine_germany' and any(r['coo_iso'] != 'UKR' or r['coa_iso'] != 'DEU' for r in items):
            raise ValueError('API не применил фильтр стран')
        meta['years'] = sorted(actual_years)
        meta['checks_passed'] = True
        checks.append(meta)
        print(name, ':', len(items), 'строк; годы', sorted(actual_years))
        for row in items:
            print(row['year'], row['coo_name'], row['coa_name'], row['refugees'])
    (ROOT / 'checks.json').write_text(json.dumps(checks, ensure_ascii=False, indent=2), encoding='utf-8')

if __name__ == '__main__':
    try:
        main()
    except Exception:
        logging.exception('Проверка API не завершена')
        raise
