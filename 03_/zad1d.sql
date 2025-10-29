INSERT INTO obiekty (nazwa, geometria)
VALUES (
    'obiekt4',
    ST_GeomFromText(
        'LINESTRING(20.5 19.5, 22 19, 26 21, 25 22, 27 24, 25 25, 20 20)',
        0
    )
);