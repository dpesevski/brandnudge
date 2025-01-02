CREATE TABLE "userExports"
(
    ID                  serial
        PRIMARY KEY,
    "userId"            integer
        REFERENCES USERS,
    NAME                varchar(255),
    FILENAME            varchar(255)              NOT NULL,
    "createdAt"         timestamp with time zone  NOT NULL,
    "updatedAt"         timestamp with time zone  NOT NULL,
    DATA                JSONB DEFAULT '{}'::JSONB NOT NULL,
    SECTION             text,
    "scheduledExportId" integer
                                                  REFERENCES "userExportsSchedules"
                                                      ON DELETE SET NULL
);

ALTER TABLE "userExports"
    OWNER TO POSTGRES;

GRANT SELECT ON "userExports" TO BN_RO;

GRANT SELECT ON "userExports" TO BN_RO_ROLE;

GRANT SELECT ON "userExports" TO BN_RO_USER1;

GRANT SELECT ON "userExports" TO DEJAN_USER;

