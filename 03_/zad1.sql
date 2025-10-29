CREATE TABLE obiekty (
    id SERIAL PRIMARY KEY,
    nazwa VARCHAR(255),
    geometria geometry(Geometry, 0)
);