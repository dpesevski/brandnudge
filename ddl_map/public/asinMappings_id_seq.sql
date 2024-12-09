CREATE SEQUENCE "asinMappings_id_seq";

ALTER SEQUENCE "asinMappings_id_seq" OWNER TO postgres;

ALTER SEQUENCE "asinMappings_id_seq" OWNED BY mappings.id;

GRANT SELECT ON SEQUENCE "asinMappings_id_seq" TO dejan_user;

