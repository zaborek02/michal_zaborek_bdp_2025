SELECT
    name,
    ST_Perimeter(geom) AS perimeter
FROM
    buildings
ORDER BY
    ST_Area(geom) DESC
LIMIT 2;