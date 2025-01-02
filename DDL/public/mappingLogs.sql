CREATE TABLE "mappingLogs"
(
    ID          serial
        PRIMARY KEY,
    LOG         JSON,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    MANUAL      boolean DEFAULT FALSE
);

ALTER TABLE "mappingLogs"
    OWNER TO POSTGRES;

GRANT SELECT ON "mappingLogs" TO BN_RO;

GRANT SELECT ON "mappingLogs" TO BN_RO_ROLE;

GRANT SELECT ON "mappingLogs" TO BN_RO_USER1;

GRANT SELECT ON "mappingLogs" TO DEJAN_USER;

