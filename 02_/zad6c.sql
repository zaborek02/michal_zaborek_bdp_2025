SELECT
    name,
    ST_Area(geom) AS area
FROM
    buildings
ORDER BY
    name;