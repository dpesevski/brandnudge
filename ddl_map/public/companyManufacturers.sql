CREATE TABLE "companyManufacturers"
(
    id               integer DEFAULT NEXTVAL('"companyManufacturers_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    "manufacturerId" integer,
    "companyId"      integer,
    "createdAt"      timestamp with time zone                                           NOT NULL,
    "updatedAt"      timestamp with time zone                                           NOT NULL
);

ALTER TABLE "companyManufacturers"
    OWNER TO postgres;

GRANT SELECT ON "companyManufacturers" TO bn_ro;

GRANT SELECT ON "companyManufacturers" TO bn_ro_role;

GRANT SELECT ON "companyManufacturers" TO bn_ro_user1;

GRANT SELECT ON "companyManufacturers" TO dejan_user;

