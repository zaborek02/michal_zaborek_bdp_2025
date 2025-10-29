CREATE TABLE input_points (
    id serial PRIMARY KEY,
    opis varchar(255),
    geom geometry(Point, 4326)
);
INSERT INTO input_points (opis, geom)
VALUES
    ('Punkt 1', ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326)),
    ('Punkt 2', ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326));