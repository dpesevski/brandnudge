CREATE SEQUENCE "coreProductTaggings_id_seq";

ALTER SEQUENCE "coreProductTaggings_id_seq" OWNER TO postgres;

ALTER SEQUENCE "coreProductTaggings_id_seq" OWNED BY "coreProductTaggings".id;

GRANT SELECT ON SEQUENCE "coreProductTaggings_id_seq" TO dejan_user;

