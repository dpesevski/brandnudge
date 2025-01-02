CREATE SEQUENCE "asinMappings_id_seq";

ALTER SEQUENCE "asinMappings_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "asinMappings_id_seq" OWNED BY MAPPINGS.ID;

GRANT SELECT ON SEQUENCE "asinMappings_id_seq" TO DEJAN_USER;

