CREATE SEQUENCE "pdsCores_id_seq";

ALTER SEQUENCE "pdsCores_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "pdsCores_id_seq" OWNED BY "pdsCores".ID;

GRANT SELECT ON SEQUENCE "pdsCores_id_seq" TO DEJAN_USER;

