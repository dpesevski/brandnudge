CREATE SEQUENCE "scrapperLinks_id_seq";

ALTER SEQUENCE "scrapperLinks_id_seq" OWNER TO postgres;

ALTER SEQUENCE "scrapperLinks_id_seq" OWNED BY "scrapperLinks".id;

GRANT SELECT ON SEQUENCE "scrapperLinks_id_seq" TO dejan_user;

