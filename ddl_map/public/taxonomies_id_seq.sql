CREATE SEQUENCE taxonomies_id_seq;

ALTER SEQUENCE taxonomies_id_seq OWNER TO postgres;

ALTER SEQUENCE taxonomies_id_seq OWNED BY taxonomies.id;

GRANT SELECT ON SEQUENCE taxonomies_id_seq TO dejan_user;

