CREATE SEQUENCE "scrapperLinks_id_seq";

ALTER SEQUENCE "scrapperLinks_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "scrapperLinks_id_seq" OWNED BY "scrapperLinks".ID;

GRANT SELECT ON SEQUENCE "scrapperLinks_id_seq" TO DEJAN_USER;

