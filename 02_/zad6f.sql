SELECT
    ST_Area(
        ST_Difference(
            (SELECT geom FROM buildings WHERE name = 'BuildingC'),
            ST_Buffer((SELECT geom FROM buildings WHERE name = 'BuildingB'), 0.5)
        )
    ) AS resulting_area;