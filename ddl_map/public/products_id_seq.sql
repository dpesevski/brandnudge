CREATE SEQUENCE products_id_seq;

ALTER SEQUENCE products_id_seq OWNER TO postgres;

ALTER SEQUENCE products_id_seq OWNED BY products.id;

GRANT SELECT ON SEQUENCE products_id_seq TO dejan_user;

