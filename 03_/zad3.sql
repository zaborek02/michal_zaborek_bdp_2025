UPDATE obiekty
SET geometria = ST_MakePolygon(
    ST_AddPoint(geometria, ST_StartPoint(geometria))
)
WHERE nazwa = 'obiekt4'
  AND ST_GeometryType(geometria) = 'ST_LineString'; 