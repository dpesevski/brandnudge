CREATE SEQUENCE companies_id_seq;

ALTER SEQUENCE companies_id_seq OWNER TO postgres;

ALTER SEQUENCE companies_id_seq OWNED BY companies.id;

GRANT SELECT ON SEQUENCE companies_id_seq TO dejan_user;

