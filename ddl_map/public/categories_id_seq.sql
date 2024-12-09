CREATE SEQUENCE categories_id_seq;

ALTER SEQUENCE categories_id_seq OWNER TO postgres;

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;

GRANT SELECT ON SEQUENCE categories_id_seq TO dejan_user;

