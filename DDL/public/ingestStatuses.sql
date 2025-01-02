CREATE TABLE "ingestStatuses"
(
    ID          serial
        PRIMARY KEY,
    ENDPOINT    varchar(255),
    STATUS      varchar(255) DEFAULT 'running'::character varying NOT NULL,
    "createdAt" timestamp with time zone                          NOT NULL,
    "updatedAt" timestamp with time zone                          NOT NULL,
    RETAILER    varchar(255)
);

ALTER TABLE "ingestStatuses"
    OWNER TO POSTGRES;

GRANT SELECT ON "ingestStatuses" TO BN_RO;

GRANT SELECT ON "ingestStatuses" TO BN_RO_ROLE;

GRANT SELECT ON "ingestStatuses" TO BN_RO_USER1;

GRANT SELECT ON "ingestStatuses" TO DEJAN_USER;

