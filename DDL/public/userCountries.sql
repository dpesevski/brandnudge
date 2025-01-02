CREATE TABLE "userCountries"
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES USERS,
    "countryId" integer
        REFERENCES COUNTRIES,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userCountries"
    OWNER TO POSTGRES;

GRANT SELECT ON "userCountries" TO BN_RO;

GRANT SELECT ON "userCountries" TO BN_RO_ROLE;

GRANT SELECT ON "userCountries" TO BN_RO_USER1;

GRANT SELECT ON "userCountries" TO DEJAN_USER;

