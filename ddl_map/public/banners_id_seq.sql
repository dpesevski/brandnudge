CREATE SEQUENCE banners_id_seq;

ALTER SEQUENCE banners_id_seq OWNER TO postgres;

ALTER SEQUENCE banners_id_seq OWNED BY banners.id;

GRANT SELECT ON SEQUENCE banners_id_seq TO dejan_user;

