CREATE TABLE "companyCountries"
(
    id          serial
        PRIMARY KEY,
    "companyId" integer
        REFERENCES companies,
    "countryId" integer
        REFERENCES countries,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "companyCountries"
    OWNER TO postgres;

GRANT SELECT ON "companyCountries" TO bn_ro;

GRANT SELECT ON "companyCountries" TO bn_ro_role;

GRANT SELECT ON "companyCountries" TO bn_ro_user1;

GRANT SELECT ON "companyCountries" TO dejan_user;

