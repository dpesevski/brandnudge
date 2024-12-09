CREATE SEQUENCE images_id_seq;

ALTER SEQUENCE images_id_seq OWNER TO postgres;

ALTER SEQUENCE images_id_seq OWNED BY images.id;

GRANT SELECT ON SEQUENCE images_id_seq TO dejan_user;

