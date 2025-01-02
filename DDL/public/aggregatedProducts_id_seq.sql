CREATE SEQUENCE "aggregatedProducts_id_seq";

ALTER SEQUENCE "aggregatedProducts_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "aggregatedProducts_id_seq" OWNED BY "aggregatedProducts".ID;

GRANT SELECT ON SEQUENCE "aggregatedProducts_id_seq" TO DEJAN_USER;

