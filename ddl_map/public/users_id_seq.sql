CREATE SEQUENCE users_id_seq;

ALTER SEQUENCE users_id_seq OWNER TO postgres;

ALTER SEQUENCE users_id_seq OWNED BY users.id;

GRANT SELECT ON SEQUENCE users_id_seq TO dejan_user;

