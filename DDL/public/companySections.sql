CREATE TABLE "companySections"
(
    ID          serial
        PRIMARY KEY,
    "companyId" integer,
    "sectionId" integer,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    UNIQUE ("companyId", "sectionId")
);

ALTER TABLE "companySections"
    OWNER TO POSTGRES;

GRANT SELECT ON "companySections" TO BN_RO;

GRANT SELECT ON "companySections" TO BN_RO_ROLE;

GRANT SELECT ON "companySections" TO BN_RO_USER1;

GRANT SELECT ON "companySections" TO DEJAN_USER;

