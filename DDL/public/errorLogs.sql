CREATE TABLE "errorLogs"
(
    ID          serial
        PRIMARY KEY,
    MESSAGE     text,
    STACK       text,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "errorLogs"
    OWNER TO POSTGRES;

GRANT SELECT ON "errorLogs" TO BN_RO;

GRANT SELECT ON "errorLogs" TO BN_RO_ROLE;

GRANT SELECT ON "errorLogs" TO BN_RO_USER1;

GRANT SELECT ON "errorLogs" TO DEJAN_USER;

