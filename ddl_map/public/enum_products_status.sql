CREATE TYPE enum_products_status AS enum ('newly', 'de-listed', 're-listed', 'available');

ALTER TYPE enum_products_status OWNER TO postgres;

