CREATE SEQUENCE "productGroups_id_seq";

ALTER SEQUENCE "productGroups_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "productGroups_id_seq" OWNED BY "productGroups".ID;

GRANT SELECT ON SEQUENCE "productGroups_id_seq" TO DEJAN_USER;

