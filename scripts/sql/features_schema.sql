-- start features_map_layers_features table
CREATE TABLE features.map_layers_features
(
  feature character varying(200) NOT NULL,
  portal_names character varying(200)[] NOT NULL,
  layer_names character varying(200)[] NOT NULL,
  CONSTRAINT map_layers_features_pkey PRIMARY KEY (feature)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE features.map_layers_features
  OWNER TO geo_dba;
GRANT ALL ON TABLE features.map_layers_features TO geo_dba;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE features.map_layers_features TO geo_api3;
-- end features_map_layers_features table