CREATE SEQUENCE "taxonomyProducts_id_seq";

ALTER SEQUENCE "taxonomyProducts_id_seq" OWNER TO postgres;

ALTER SEQUENCE "taxonomyProducts_id_seq" OWNED BY "taxonomyProducts".id;

GRANT SELECT ON SEQUENCE "taxonomyProducts_id_seq" TO dejan_user;

