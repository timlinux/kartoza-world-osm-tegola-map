CREATE INDEX type_idx ON osm.osm_roads(type);
CREATE INDEX admin_level_idx ON osm.osm_admin(admin_level);
CREATE INDEX place_idx ON osm.osm_places(place);

CREATE INDEX roads_geom_idx ON osm.osm_roads USING GIST (geometry);
CREATE INDEX rivers_geom_idx ON osm.osm_waterways_rivers USING GIST (geometry);
CREATE INDEX streams_geom_idx ON osm.osm_waterways_streams USING GIST (geometry);
CREATE INDEX admin_geom_idx ON osm.osm_admin USING GIST (geometry);
CREATE INDEX places_geom_idx ON osm.osm_places USING GIST (geometry);
CREATE INDEX buildings_geom_idx ON osm.osm_buildings USING GIST (geometry);