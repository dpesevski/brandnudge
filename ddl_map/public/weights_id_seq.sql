CREATE SEQUENCE weights_id_seq;

ALTER SEQUENCE weights_id_seq OWNER TO postgres;

ALTER SEQUENCE weights_id_seq OWNED BY weights.id;

GRANT SELECT ON SEQUENCE weights_id_seq TO dejan_user;

