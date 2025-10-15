SELECT
    name,
    geom
FROM
    buildings
WHERE
    ST_Y(ST_Centroid(geom)) > (SELECT ST_Y(ST_StartPoint(geom)) FROM roads WHERE name = 'RoadX');