CREATE SEQUENCE coretaggings_id_seq;

ALTER SEQUENCE coretaggings_id_seq OWNER TO postgres;

ALTER SEQUENCE coretaggings_id_seq OWNED BY "coreTaggings".id;

GRANT SELECT ON SEQUENCE coretaggings_id_seq TO dejan_user;

