INSERT INTO obiekty (nazwa, geometria)
VALUES (
    'obiekt3',
    ST_GeomFromText(
        'POLYGON((7 15, 10 17, 12 13, 7 15))',
        0
    )
);