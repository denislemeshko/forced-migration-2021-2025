-- Сравнение трёх выбранных стран на конец 2025 года.
-- Изменения рассчитаны относительно конца 2024 года.
SELECT origin, refugees, change_people, change_percent
FROM refugee_origins
WHERE year = 2025
ORDER BY refugees DESC;

-- Доли трёх стран в мировом показателе refugees.
SELECT
    o.origin,
    o.year,
    o.refugees,
    w.refugees AS world_refugees,
    ROUND(
        100.0 * o.refugees / NULLIF(w.refugees, 0),
        2
    ) AS share_percent
FROM refugee_origins AS o
JOIN refugee_world AS w ON o.year = w.year
WHERE o.year = 2025
ORDER BY share_percent DESC;

-- Общая доля трёх выбранных стран.
SELECT
    o.year,
    SUM(o.refugees) AS selected_countries_refugees,
    w.refugees AS world_refugees,
    ROUND(
        100.0 * SUM(o.refugees) / NULLIF(w.refugees, 0),
        2
    ) AS share_percent
FROM refugee_origins AS o
JOIN refugee_world AS w ON o.year = w.year
WHERE o.year = 2025
  AND o.origin IN ('UKR', 'SYR', 'AFG')
GROUP BY o.year, w.refugees;

-- Доля Украины, Сирии и Афганистана по годам.
SELECT
    o.year,
    SUM(o.refugees) AS selected_countries_refugees,
    w.refugees AS world_refugees,
    ROUND(
        100.0 * SUM(o.refugees) / NULLIF(w.refugees, 0),
        2
    ) AS share_percent
FROM refugee_origins AS o
JOIN refugee_world AS w ON o.year = w.year
WHERE o.year BETWEEN 2021 AND 2025
  AND o.origin IN ('UKR', 'SYR', 'AFG')
GROUP BY o.year, w.refugees
ORDER BY o.year;