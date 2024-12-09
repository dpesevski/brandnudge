CREATE SEQUENCE "pdsData_id_seq";

ALTER SEQUENCE "pdsData_id_seq" OWNER TO postgres;

ALTER SEQUENCE "pdsData_id_seq" OWNED BY "pdsData".id;

GRANT SELECT ON SEQUENCE "pdsData_id_seq" TO dejan_user;

