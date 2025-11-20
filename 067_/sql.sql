--------------------------------------------------------------------------------
-- 1. KONFIGURACJA ŚRODOWISKA I SCHEMATÓW
--------------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Utworzenie schematów logicznych
CREATE SCHEMA IF NOT EXISTS source_data;       -- Dane wejściowe
CREATE SCHEMA IF NOT EXISTS processing_results; -- Wyniki analiz

-- Ewentualna migracja starego schematu (jeśli istnieje)
ALTER SCHEMA IF EXISTS schema_name RENAME TO processing_results;

--------------------------------------------------------------------------------
-- 2. OPERACJE NA DANYCH RASTROWYCH: PRZYCINANIE I SELEKCJA
--------------------------------------------------------------------------------

-- 2.1. Selekcja rastrów (DEM) przecinających się z obszarem badanym
CREATE TABLE processing_results.dem_intersected AS
SELECT r.rast, v.name_label
FROM source_data.dem_global AS r
JOIN source_data.parcels_boundary AS v
  ON ST_Intersects(r.rast, v.geom)
WHERE v.name_label ILIKE 'study_region_a';

ALTER TABLE processing_results.dem_intersected ADD COLUMN tile_id SERIAL PRIMARY KEY;

CREATE INDEX idx_dem_int_rast_gist ON processing_results.dem_intersected USING gist (ST_ConvexHull(rast));
SELECT AddRasterConstraints('processing_results'::name, 'dem_intersected'::name, 'rast'::name);

-- 2.2. Fizyczne przycięcie rastra do granic wektora (Clipping)
CREATE TABLE processing_results.dem_clipped AS
SELECT ST_Clip(r.rast, v.geom, true) AS clipped_rast, v.name_label
FROM source_data.dem_global AS r
JOIN source_data.parcels_boundary AS v
  ON ST_Intersects(r.rast, v.geom)
WHERE v.name_label LIKE 'STUDY_REGION_A';

-- 2.3. Agregacja (Union) przyciętych fragmentów w jeden raster
CREATE TABLE processing_results.dem_merged AS
SELECT ST_Union(ST_Clip(r.rast, v.geom, true)) AS merged_rast
FROM source_data.dem_global AS r
JOIN source_data.parcels_boundary AS v
  ON ST_Intersects(r.rast, v.geom)
WHERE v.name_label ILIKE 'study_region_a';

--------------------------------------------------------------------------------
-- 3. RASTERYZACJA I KAFELKOWANIE (VECTOR -> RASTER)
--------------------------------------------------------------------------------

-- 3.1. Konwersja wektora na raster (na bazie rastra referencyjnego)
DROP TABLE IF EXISTS processing_results.vector_rasterized;

CREATE TABLE processing_results.vector_rasterized AS
WITH ref_raster AS (
    SELECT rast FROM source_data.dem_global LIMIT 1
)
SELECT ST_Union(ST_AsRaster(v.geom, ref.rast, '8BUI', v.geo_id, -32767)) AS rasterized_geom
FROM source_data.parcels_boundary AS v, ref_raster AS ref
WHERE v.name_label ILIKE 'study_region_a';

-- 3.2. Podział wyniku na regularne kafelki (Tiling 128x128)
DROP TABLE IF EXISTS processing_results.raster_tiled;

CREATE TABLE processing_results.raster_tiled AS
WITH ref_raster AS (
    SELECT rast FROM source_data.dem_global LIMIT 1
),
full_raster AS (
    SELECT ST_Union(ST_AsRaster(v.geom, ref.rast, '8BUI', v.geo_id, -32767)) AS rast
    FROM source_data.parcels_boundary AS v, ref_raster AS ref
    WHERE v.name_label ILIKE 'study_region_a'
)
SELECT ST_Tile(f.rast, 128, 128, true, -32767) AS tiled_rast
FROM full_raster AS f;

--------------------------------------------------------------------------------
-- 4. KONWERSJA RASTER -> VECTOR I EKSTRAKCJA DANYCH
--------------------------------------------------------------------------------

-- 4.1. Przecięcie geometryczne (Intersection)
CREATE TABLE processing_results.pixel_intersection AS
SELECT r.tile_id,
       (ST_Intersection(v.geom, r.rast)).geom AS geom_val,
       (ST_Intersection(v.geom, r.rast)).val AS pixel_val
FROM source_data.satellite_tiles AS r
JOIN source_data.parcels_boundary AS v
  ON ST_Intersects(v.geom, r.rast)
WHERE v.sub_area_name ILIKE 'sub_unit_alpha';

-- 4.2. Konwersja na poligony (DumpAsPolygons)
CREATE TABLE processing_results.pixel_polygons AS
SELECT r.tile_id,
       (ST_DumpAsPolygons(ST_Clip(r.rast, v.geom))).geom AS poly_geom,
       (ST_DumpAsPolygons(ST_Clip(r.rast, v.geom))).val AS poly_val
FROM source_data.satellite_tiles AS r
JOIN source_data.parcels_boundary AS v
  ON ST_Intersects(v.geom, r.rast)
WHERE v.sub_area_name ILIKE 'sub_unit_alpha';

-- 4.3. Pobranie wartości dla punktów (Point Sampling)
SELECT pts.name_label, ST_Value(r.rast, (ST_Dump(pts.geom)).geom) AS elevation_val
FROM source_data.dem_global AS r
JOIN source_data.points_of_interest AS pts
  ON ST_Intersects(r.rast, pts.geom)
ORDER BY pts.name_label;

--------------------------------------------------------------------------------
-- 5. ANALIZA TERENU (DEM PROCESSING)
--------------------------------------------------------------------------------

-- 5.1. Przygotowanie wycinka DEM
CREATE TABLE processing_results.sub_dem AS
SELECT r.tile_id, ST_Clip(r.rast, v.geom, true) AS rast
FROM source_data.dem_global AS r
JOIN source_data.parcels_boundary AS v
  ON ST_Intersects(v.geom, r.rast)
WHERE v.sub_area_name ILIKE 'sub_unit_alpha';

-- 5.2. Nachylenie (Slope) i Reklasyfikacja
CREATE TABLE processing_results.sub_slope_reclass AS
WITH slope_calc AS (
    SELECT tile_id, ST_Slope(rast, 1, '32BF', 'PERCENTAGE') AS slope_rast
    FROM processing_results.sub_dem
)
SELECT tile_id, ST_Reclass(slope_rast, 1, ']0-15]:1, (15-30]:2, (30-9999:3', '32BF', 0) AS reclass_rast
FROM slope_calc;

-- 5.3. Statystyki (SummaryStats)
WITH stats_agg AS (
    SELECT v.sub_area_name,
           ST_SummaryStats(ST_Union(ST_Clip(r.rast, v.geom, true))) AS stats
    FROM source_data.dem_global AS r
    JOIN source_data.parcels_boundary AS v
      ON ST_Intersects(v.geom, r.rast)
    WHERE v.name_label ILIKE 'study_region_a'
    GROUP BY v.sub_area_name
)
SELECT sub_area_name, (stats).min, (stats).max, (stats).mean FROM stats_agg;

-- 5.4. TPI (Topographic Position Index)
CREATE TABLE processing_results.tpi_calc AS
SELECT ST_TPI(r.rast, 1) AS tpi_rast
FROM source_data.dem_global AS r
JOIN source_data.parcels_boundary AS v
  ON ST_Intersects(r.rast, v.geom)
WHERE v.name_label ILIKE 'study_region_a';

CREATE INDEX idx_tpi_gist ON processing_results.tpi_calc USING gist (ST_ConvexHull(tpi_rast));
SELECT AddRasterConstraints('processing_results'::name, 'tpi_calc'::name, 'tpi_rast'::name);

--------------------------------------------------------------------------------
-- 6. ALGEBRA MAP (NDVI CALCULATION)
--------------------------------------------------------------------------------

-- 6.1. Funkcja pomocnicza dla algebry map
CREATE OR REPLACE FUNCTION processing_results.calc_ndvi_callback(
    val double precision[][][][],
    pos integer[][],
    VARIADIC userargs text[]
) RETURNS double precision AS $$
BEGIN
    -- (NIR - RED) / (NIR + RED) -> Band 2 (NIR) vs Band 1 (RED) w tablicy wejściowej
    RETURN (val[2][1][1] - val[1][1][1]) / (val[2][1][1] + val[1][1][1]);
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

-- 6.2. Wyliczenie NDVI z wykorzystaniem funkcji
CREATE TABLE processing_results.ndvi_output AS
WITH clipped_sat AS (
    SELECT r.tile_id, ST_Clip(r.rast, v.geom, true) AS rast
    FROM source_data.satellite_tiles AS r
    JOIN source_data.parcels_boundary AS v
      ON ST_Intersects(v.geom, r.rast)
    WHERE v.name_label ILIKE 'study_region_a'
)
SELECT tile_id,
       ST_MapAlgebra(
           rast, ARRAY[1,4], -- Pasma: 1 (Red) i 4 (NIR)
           'processing_results.calc_ndvi_callback(double precision[], integer[], text[])'::regprocedure,
           '32BF'
       ) AS ndvi_rast
FROM clipped_sat;

CREATE INDEX idx_ndvi_gist ON processing_results.ndvi_output USING gist (ST_ConvexHull(ndvi_rast));
SELECT AddRasterConstraints('processing_results'::name, 'ndvi_output'::name, 'ndvi_rast'::name);