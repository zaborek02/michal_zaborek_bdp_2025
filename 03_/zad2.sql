SELECT
    ST_Area(
        ST_Buffer(
            ST_ShortestLine(t1.geometria, t2.geometria),
            5
        )
    ) AS pole_powierzchni_bufora
FROM
    (SELECT geometria FROM obiekty WHERE nazwa = 'obiekt3') AS t1,
    (SELECT geometria FROM obiekty WHERE nazwa = 'obiekt4') AS t2;