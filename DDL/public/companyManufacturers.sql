CREATE TABLE "companyManufacturers"
(
    ID               integer DEFAULT NEXTVAL('"companyManufacturers_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    "manufacturerId" integer,
    "companyId"      integer,
    "createdAt"      timestamp with time zone                                           NOT NULL,
    "updatedAt"      timestamp with time zone                                           NOT NULL
);

ALTER TABLE "companyManufacturers"
    OWNER TO POSTGRES;

GRANT SELECT ON "companyManufacturers" TO BN_RO;

GRANT SELECT ON "companyManufacturers" TO BN_RO_ROLE;

GRANT SELECT ON "companyManufacturers" TO BN_RO_USER1;

GRANT SELECT ON "companyManufacturers" TO DEJAN_USER;

