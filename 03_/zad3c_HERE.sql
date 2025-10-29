CREATE TABLE streets_reprojected AS
SELECT
    gid,
    link_id,
    st_name,
    ref_in_id,
    nref_in_id,
    func_class,
    speed_cat,
    fr_speed_l,
    to_speed_l,
    dir_travel,
    ST_Transform(ST_SetSRID(geom, 4326), 3068) AS geom

FROM
    "t2019_kar_streets";
CREATE INDEX idx_streets_reprojected_geom_gist
ON streets_reprojected
USING GIST (geom);