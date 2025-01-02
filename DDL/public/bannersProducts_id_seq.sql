CREATE SEQUENCE "bannersProducts_id_seq";

ALTER SEQUENCE "bannersProducts_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "bannersProducts_id_seq" OWNED BY "bannersProducts".ID;

GRANT SELECT ON SEQUENCE "bannersProducts_id_seq" TO DEJAN_USER;

