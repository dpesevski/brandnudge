CREATE SEQUENCE "aggregatedProducts_id_seq";

ALTER SEQUENCE "aggregatedProducts_id_seq" OWNER TO postgres;

ALTER SEQUENCE "aggregatedProducts_id_seq" OWNED BY "aggregatedProducts".id;

GRANT SELECT ON SEQUENCE "aggregatedProducts_id_seq" TO dejan_user;

