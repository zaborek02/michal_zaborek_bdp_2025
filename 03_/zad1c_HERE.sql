SELECT
    t2019.*,
    'Nowy budynek' AS status_zmiany
FROM
    "t2019_kar_buildings" AS t2019
LEFT JOIN
    "t2018_kar_buildings" AS t2018
    ON t2019.polygon_id = t2018.polygon_id
WHERE
    t2018.polygon_id IS NULL

UNION

SELECT
    t2019.*,
    'Budynek po remoncie/zmianie' AS status_zmiany
FROM
    "t2019_kar_buildings" AS t2019
JOIN
    "t2018_kar_buildings" AS t2018
    ON t2019.polygon_id = t2018.polygon_id
WHERE
    t2019.name IS DISTINCT FROM t2018.name
    OR t2019.type IS DISTINCT FROM t2018.type
    OR NOT ST_Equals(t2019.geom, t2018.geom);