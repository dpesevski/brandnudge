CREATE SEQUENCE "coreProducts_id_seq";

ALTER SEQUENCE "coreProducts_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "coreProducts_id_seq" OWNED BY "coreProducts".ID;

GRANT SELECT ON SEQUENCE "coreProducts_id_seq" TO DEJAN_USER;

