-- start api3_url_shortener table
CREATE TABLE api3.url_shortener
(
  short_url character varying(10) NOT NULL, -- The original URL with protocal and host
  url character varying(2048) NOT NULL,
  createtime timestamp without time zone NOT NULL, -- The timestamp of creation
  accesstime timestamp without time zone NOT NULL,
  portal character varying(200) DEFAULT NULL::character varying,
  CONSTRAINT url_shortener_pkey PRIMARY KEY (short_url)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE api3.url_shortener
  OWNER TO geo_dba;
GRANT ALL ON TABLE api3.url_shortener TO geo_dba;
GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE api3.url_shortener TO geo_api3;
COMMENT ON TABLE api3.url_shortener
  IS 'Storage for url';
COMMENT ON COLUMN api3.url_shortener.short_url IS 'The original URL with protocal and host';
COMMENT ON COLUMN api3.url_shortener.createtime IS 'The timestamp of creation';
-- end api3_url_shortener table


-- start api3_files table
CREATE TABLE api3.files
(
  admin_id character varying(24) NOT NULL,
  file_id character varying(24) NOT NULL,
  mime_type character varying(50) NOT NULL, -- The MIME Type of the stored file.
  createtime timestamp without time zone NOT NULL DEFAULT now(),
  accesstime timestamp without time zone NOT NULL,
  portal character varying(200) DEFAULT NULL::character varying,
  CONSTRAINT pk_file_id PRIMARY KEY (admin_id, file_id),
  CONSTRAINT files_admin_id_key UNIQUE (admin_id),
  CONSTRAINT files_file_id_key UNIQUE (file_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE api3.files
  OWNER TO geo_dba;
GRANT ALL ON TABLE api3.files TO geo_dba;
GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES, TRIGGER ON TABLE api3.files TO geo_api3;
COMMENT ON TABLE api3.files
  IS 'Link between file and admin ids.';
COMMENT ON COLUMN api3.files.mime_type IS 'The MIME Type of the stored file.';
-- end api3_files table
