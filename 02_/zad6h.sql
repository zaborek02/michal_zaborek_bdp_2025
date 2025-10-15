SELECT
    ST_Area(
        ST_SymDifference(
            (SELECT geom FROM buildings WHERE name = 'BuildingC'),
            ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')
        )
    ) AS non_common_area;