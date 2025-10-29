INSERT INTO obiekty (nazwa, geometria)
SELECT
    'obiekt7',
    ST_Union(g3.geometria, g4.geometria)
FROM
    (SELECT geometria FROM obiekty WHERE nazwa = 'obiekt3') AS g3,
    (SELECT geometria FROM obiekty WHERE nazwa = 'obiekt4') AS g4;