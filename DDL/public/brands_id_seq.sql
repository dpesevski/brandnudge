CREATE SEQUENCE BRANDS_ID_SEQ;

ALTER SEQUENCE BRANDS_ID_SEQ OWNER TO POSTGRES;

ALTER SEQUENCE BRANDS_ID_SEQ OWNED BY BRANDS.ID;

GRANT SELECT ON SEQUENCE BRANDS_ID_SEQ TO DEJAN_USER;

