INSERT INTO obiekty (nazwa, geometria)
VALUES (
    'obiekt5',
    ST_GeomFromText(
        'MULTIPOINT Z ((38 32 234), (30 30 59))',
        0
    )
);