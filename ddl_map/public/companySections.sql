CREATE TABLE "companySections"
(
    id          serial
        PRIMARY KEY,
    "companyId" integer,
    "sectionId" integer,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    UNIQUE ("companyId", "sectionId")
);

ALTER TABLE "companySections"
    OWNER TO postgres;

GRANT SELECT ON "companySections" TO bn_ro;

GRANT SELECT ON "companySections" TO bn_ro_role;

GRANT SELECT ON "companySections" TO bn_ro_user1;

GRANT SELECT ON "companySections" TO dejan_user;

