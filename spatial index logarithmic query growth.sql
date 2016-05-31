-- The following script has been tested on Postgres 9.4 with PostGIS 2.1
-- It demonstrates the key property of a spatial index - namely that if
-- query result sizes are held constant, then query speed should grow
-- logarithmically as table size grows linearly. This is for simple queries
-- of the form "find me all the geometries inside this box".
-- This is similar to the performance one expects of a BTree index, given a
-- similar set of constraints.

-- Create a table that has a geometry field with SRID 3857, which is the standard
-- Web Maps coordinate system.
DROP TABLE IF EXISTS tab;
CREATE TABLE tab (rowid BIGSERIAL PRIMARY KEY);
SELECT AddGeometryColumn ('public', 'tab', 'geometry', 3857, 'POLYGON', 2);

-- Create a spatial index on the geometry field
CREATE INDEX idx_tab_geometry ON tab USING GIST (geometry);

-- Insert a square polygon that fits within the unit square (0,0 - 1,1)
INSERT INTO tab (geometry) VALUES (ST_GeomFromText('POLYGON ((0.0546875 0.0546875,0.953125 0.0546875,0.953125 0.9453124999,0.0546875 0.9453124999,0.0546875 0.0546875))', 3857));

-- Duplicate our dataset several times horizontally, so that we end up with a long row of 1024 squares
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 1, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 2, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 4, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 8, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 16, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 32, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 64, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 128, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 256, 0) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 512, 0) FROM tab);

-- Duplicate our dataset several times again, but now translate vertically
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 1) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 2) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 4) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 8) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 16) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 32) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 64) FROM tab);

-- Measure the performance of the following query, which in words, is doing this:
-- Select all geometries that overlap the box from (0,0) to (10,10), and compute
-- the minimum X coordinate of all of those geometries.

EXPLAIN ANALYZE SELECT min(ST_XMin(geometry)) FROM tab WHERE geometry && ST_SetSRID('BOX(0 0, 10 10)'::BOX2D, 3857);

-- Over the next four growth stages, run the above 'EXPLAIN ANALYZE' statement again,
-- each time noting the "Execution time" of the query. We expect it to grow very slowly,
-- and to remain close to 0.5 milliseconds or less.
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 128) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 256) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 512) FROM tab);
INSERT INTO tab (geometry) (SELECT ST_Translate(geometry, 0, 1024) FROM tab);
