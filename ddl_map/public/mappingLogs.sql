CREATE TABLE "mappingLogs"
(
    id          serial
        PRIMARY KEY,
    log         json,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    manual      boolean DEFAULT FALSE
);

ALTER TABLE "mappingLogs"
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "mappingLogs_pkey" TO postgres;

GRANT SELECT ON "mappingLogs_pkey" TO bn_ro;

GRANT SELECT ON "mappingLogs_pkey" TO bn_ro_role;

GRANT SELECT ON "mappingLogs_pkey" TO bn_ro_user1;

GRANT SELECT ON "mappingLogs_pkey" TO dejan_user;

