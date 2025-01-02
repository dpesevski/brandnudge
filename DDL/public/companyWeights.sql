CREATE TABLE "companyWeights"
(
    ID          serial
        PRIMARY KEY,
    NAME        varchar(255)             NOT NULL,
    VALUE       text,
    "companyId" integer                  NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "companyWeights"
    OWNER TO POSTGRES;

GRANT SELECT ON "companyWeights" TO BN_RO;

GRANT SELECT ON "companyWeights" TO BN_RO_ROLE;

GRANT SELECT ON "companyWeights" TO BN_RO_USER1;

GRANT SELECT ON "companyWeights" TO DEJAN_USER;

