CREATE SEQUENCE "companyManufacturers_id_seq";

ALTER SEQUENCE "companyManufacturers_id_seq" OWNER TO postgres;

ALTER SEQUENCE "companyManufacturers_id_seq" OWNED BY "companyManufacturers".id;

GRANT SELECT ON SEQUENCE "companyManufacturers_id_seq" TO dejan_user;

