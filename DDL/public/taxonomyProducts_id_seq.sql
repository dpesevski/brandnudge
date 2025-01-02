CREATE SEQUENCE "taxonomyProducts_id_seq";

ALTER SEQUENCE "taxonomyProducts_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "taxonomyProducts_id_seq" OWNED BY "taxonomyProducts".ID;

GRANT SELECT ON SEQUENCE "taxonomyProducts_id_seq" TO DEJAN_USER;

