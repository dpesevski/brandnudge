CREATE SEQUENCE "productGroups_id_seq";

ALTER SEQUENCE "productGroups_id_seq" OWNER TO postgres;

ALTER SEQUENCE "productGroups_id_seq" OWNED BY "productGroups".id;

GRANT SELECT ON SEQUENCE "productGroups_id_seq" TO dejan_user;

