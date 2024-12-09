CREATE SEQUENCE "coreProducts_id_seq";

ALTER SEQUENCE "coreProducts_id_seq" OWNER TO postgres;

ALTER SEQUENCE "coreProducts_id_seq" OWNED BY "coreProducts".id;

GRANT SELECT ON SEQUENCE "coreProducts_id_seq" TO dejan_user;

