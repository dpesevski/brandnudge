CREATE SEQUENCE "bannersProducts_id_seq";

ALTER SEQUENCE "bannersProducts_id_seq" OWNER TO postgres;

ALTER SEQUENCE "bannersProducts_id_seq" OWNED BY "bannersProducts".id;

GRANT SELECT ON SEQUENCE "bannersProducts_id_seq" TO dejan_user;

