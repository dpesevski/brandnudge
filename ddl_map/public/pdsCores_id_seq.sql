CREATE SEQUENCE "pdsCores_id_seq";

ALTER SEQUENCE "pdsCores_id_seq" OWNER TO postgres;

ALTER SEQUENCE "pdsCores_id_seq" OWNED BY "pdsCores".id;

GRANT SELECT ON SEQUENCE "pdsCores_id_seq" TO dejan_user;

