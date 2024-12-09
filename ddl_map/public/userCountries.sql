CREATE TABLE "userCountries"
(
    id          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES users,
    "countryId" integer
        REFERENCES countries,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userCountries"
    OWNER TO postgres;

GRANT SELECT ON "userCountries" TO bn_ro;

GRANT SELECT ON "userCountries" TO bn_ro_role;

GRANT SELECT ON "userCountries" TO bn_ro_user1;

GRANT SELECT ON "userCountries" TO dejan_user;

