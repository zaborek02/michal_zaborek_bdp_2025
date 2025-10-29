SELECT
    SUM(
        ST_Area(
            ST_Buffer(geometria, 5)
        )
    ) AS laczne_pole_powierzchni_buforow
FROM
    obiekty
WHERE
    ST_GeometryType(geometria) NOT IN (
        'ST_CompoundCurve',
        'ST_CurvePolygon'
    );