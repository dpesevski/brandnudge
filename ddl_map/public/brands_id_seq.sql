CREATE SEQUENCE brands_id_seq;

ALTER SEQUENCE brands_id_seq OWNER TO postgres;

ALTER SEQUENCE brands_id_seq OWNED BY brands.id;

GRANT SELECT ON SEQUENCE brands_id_seq TO dejan_user;

