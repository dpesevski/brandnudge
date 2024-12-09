CREATE TABLE "userExports"
(
    id                  serial
        PRIMARY KEY,
    "userId"            integer
        REFERENCES users,
    name                varchar(255),
    filename            varchar(255)              NOT NULL,
    "createdAt"         timestamp with time zone  NOT NULL,
    "updatedAt"         timestamp with time zone  NOT NULL,
    data                jsonb DEFAULT '{}'::jsonb NOT NULL,
    section             text,
    "scheduledExportId" integer
                                                  REFERENCES "userExportsSchedules"
                                                      ON DELETE SET NULL
);

ALTER TABLE "userExports"
    OWNER TO postgres;

GRANT SELECT ON "userExports" TO bn_ro;

GRANT SELECT ON "userExports" TO bn_ro_role;

GRANT SELECT ON "userExports" TO bn_ro_user1;

GRANT SELECT ON "userExports" TO dejan_user;

