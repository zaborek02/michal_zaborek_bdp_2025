INSERT INTO obiekty (nazwa, geometria)
VALUES (
    'obiekt1',
    ST_GeomFromText(
        'COMPOUNDCURVE(
            LINESTRING(0 1, 1 1),
            CIRCULARSTRING(1 1, 2 0, 3 1),
            CIRCULARSTRING(3 1, 4 2, 5 1),
            LINESTRING(5 1, 6 1)
        )',
        0
    )
);