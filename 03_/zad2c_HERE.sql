
WITH
changed_buildings AS (
    SELECT t2019.geom
    FROM "t2019_kar_buildings" AS t2019
    LEFT JOIN "t2018_kar_buildings" AS t2018
        ON t2019.polygon_id = t2018.polygon_id
    WHERE t2018.polygon_id IS NULL

    UNION

    SELECT t2019.geom
    FROM "t2019_kar_buildings" AS t2019
    JOIN "t2018_kar_buildings" AS t2018
        ON t2019.polygon_id = t2018.polygon_id
    WHERE
        t2019.name IS DISTINCT FROM t2018.name
        OR t2019.type IS DISTINCT FROM t2018.type
        OR NOT ST_Equals(t2019.geom, t2018.geom)
),

changed_buildings_geog AS (
    SELECT ST_SetSRID(geom, 4326)::geography AS geog
    FROM changed_buildings
),


new_pois AS (
    SELECT
        t2019.poi_id,
        t2019.type,
        t2019.lon,
        t2019.lat
    FROM "t2019_kar_pi" AS t2019
    LEFT JOIN "t2018_kar_pi" AS t2018
        ON t2019.poi_id = t2018.poi_id
    WHERE t2018.poi_id IS NULL
),

new_pois_geog AS (
    SELECT
        type,

        ST_MakePoint(lon, lat)::geography AS geog
    FROM new_pois
)


SELECT
    p.type,
    COUNT(*) AS liczba_nowych_poi
FROM
    new_pois_geog AS p
WHERE

    EXISTS (
        SELECT 1
        FROM changed_buildings_geog AS b
        WHERE ST_DWithin(p.geog, b.geog, 500)
    )
GROUP BY
    p.type
ORDER BY
    liczba_nowych_poi DESC;