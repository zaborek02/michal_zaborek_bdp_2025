SELECT ST_Distance(
    (SELECT geom FROM buildings WHERE name = 'BuildingC'),
    (SELECT geom FROM poi WHERE name = 'K')
) AS shortest_distance;