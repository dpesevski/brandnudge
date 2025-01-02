CREATE SEQUENCE "coreProductTaggings_id_seq";

ALTER SEQUENCE "coreProductTaggings_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "coreProductTaggings_id_seq" OWNED BY "coreProductTaggings".ID;

GRANT SELECT ON SEQUENCE "coreProductTaggings_id_seq" TO DEJAN_USER;

