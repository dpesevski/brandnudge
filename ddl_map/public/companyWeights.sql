CREATE TABLE "companyWeights"
(
    id          serial
        PRIMARY KEY,
    name        varchar(255)             NOT NULL,
    value       text,
    "companyId" integer                  NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "companyWeights"
    OWNER TO postgres;

GRANT SELECT ON "companyWeights" TO bn_ro;

GRANT SELECT ON "companyWeights" TO bn_ro_role;

GRANT SELECT ON "companyWeights" TO bn_ro_user1;

GRANT SELECT ON "companyWeights" TO dejan_user;

