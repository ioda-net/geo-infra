--
-- run this script with DEFAULT_DB_OWNER
--
DO $$
-- roles[1] has to always be geo_dba, [2] geo_api
DECLARE roles varchar[] := array['DEFAULT_DB_OWNER','DEFAULT_DB_API_ROLE','DEFAULT_DB_SEARCH_ROLE','DEFAULT_DB_MAPSERVER_ROLE'];
DECLARE ro varchar;
DECLARE r record;
DECLARE o record;
BEGIN
    FOR r IN select schemaname from pg_catalog.pg_tables
              where schemaname in ('api3','edit','features','search','osm','public','userdata','topology')
              group by schemaname
              order by schemaname
    LOOP
          -- Give back all rights to owner
          EXECUTE '
            GRANT ALL ON SCHEMA ' || quote_ident(r.schemaname) || ' TO ' || quote_ident(roles[1]) || ';
            GRANT ALL ON ALL TABLES IN SCHEMA '  || quote_ident(r.schemaname) || ' TO ' || quote_ident(roles[1]) || ';
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA '  || quote_ident(r.schemaname) || ' TO '|| quote_ident(roles[1]) || ';
          ';
        
        IF r.schemaname = 'public' THEN
          -- Only owner as full rights here
          -- Could be redondant with previous execution.
          EXECUTE '
            GRANT SELECT, REFERENCES, TRIGGER ON TABLE '  || quote_ident(r.schemaname) || '.spatial_ref_sys TO '|| quote_ident(roles[1]) || ';
            GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE ' || quote_ident(r.schemaname) || '.geography_columns TO '|| quote_ident(roles[1]) || ';
            GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE ' || quote_ident(r.schemaname) || '.geometry_columns TO ' || quote_ident(roles[1]) || ';
            GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE ' || quote_ident(r.schemaname) || '.raster_columns TO '   || quote_ident(roles[1]) || ';
            GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE ' || quote_ident(r.schemaname) || '.raster_overviews TO ' || quote_ident(roles[1]) || ';
          ';
        END IF;

        -- Make all other read only
        FOREACH ro IN ARRAY roles
        LOOP
          IF ro != roles[1] THEN
          -- RAISE NOTICE 'Owner is now %', ro;
           -- Remove any rights from other than owner
           -- And redistribute correctly rights
          EXECUTE '
            REVOKE ALL ON SCHEMA ' || quote_ident(r.schemaname) || ' FROM ' || quote_ident(ro) || ';
            REVOKE ALL ON ALL TABLES IN SCHEMA '  || quote_ident(r.schemaname) || ' FROM '|| quote_ident(ro) || ';
            REVOKE ALL ON ALL FUNCTIONS IN SCHEMA '  || quote_ident(r.schemaname) || ' FROM '|| quote_ident(ro) || ';
            GRANT USAGE ON SCHEMA '  || quote_ident(r.schemaname) || ' TO '|| quote_ident(ro) || ';
            GRANT SELECT, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA '  || quote_ident(r.schemaname) || ' TO '|| quote_ident(ro) || ';
            GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA '  || quote_ident(r.schemaname) || ' TO '|| quote_ident(ro) || ';
          ';
          END IF;

          -- Special case for api schema where geo_api need control on some tables
          IF r.schemaname = 'api3' AND ro = roles[2] THEN
          EXECUTE '
            GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE '  || quote_ident(r.schemaname) || '.url_shortener TO ' || quote_ident(roles[2]) || ';
            GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE '  || quote_ident(r.schemaname) || '.files TO ' || quote_ident(roles[2]) || ';
          ';
          END IF;
          
        END LOOP; -- End roles
        
    END LOOP; -- End schemas
END$$;

