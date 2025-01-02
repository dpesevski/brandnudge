CREATE TABLE "companyCountries"
(
    ID          serial
        PRIMARY KEY,
    "companyId" integer
        REFERENCES COMPANIES,
    "countryId" integer
        REFERENCES COUNTRIES,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "companyCountries"
    OWNER TO POSTGRES;

GRANT SELECT ON "companyCountries" TO BN_RO;

GRANT SELECT ON "companyCountries" TO BN_RO_ROLE;

GRANT SELECT ON "companyCountries" TO BN_RO_USER1;

GRANT SELECT ON "companyCountries" TO DEJAN_USER;

