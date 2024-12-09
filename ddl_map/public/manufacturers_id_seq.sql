CREATE SEQUENCE manufacturers_id_seq;

ALTER SEQUENCE manufacturers_id_seq OWNER TO postgres;

ALTER SEQUENCE manufacturers_id_seq OWNED BY manufacturers.id;

GRANT SELECT ON SEQUENCE manufacturers_id_seq TO dejan_user;

