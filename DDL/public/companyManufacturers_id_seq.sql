CREATE SEQUENCE "companyManufacturers_id_seq";

ALTER SEQUENCE "companyManufacturers_id_seq" OWNER TO POSTGRES;

ALTER SEQUENCE "companyManufacturers_id_seq" OWNED BY "companyManufacturers".ID;

GRANT SELECT ON SEQUENCE "companyManufacturers_id_seq" TO DEJAN_USER;

