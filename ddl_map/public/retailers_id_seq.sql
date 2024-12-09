CREATE SEQUENCE retailers_id_seq;

ALTER SEQUENCE retailers_id_seq OWNER TO postgres;

ALTER SEQUENCE retailers_id_seq OWNED BY retailers.id;

GRANT SELECT ON SEQUENCE retailers_id_seq TO dejan_user;

