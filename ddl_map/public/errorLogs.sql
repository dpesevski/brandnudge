CREATE TABLE "errorLogs"
(
    id          serial
        PRIMARY KEY,
    message     text,
    stack       text,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "errorLogs"
    OWNER TO postgres;

GRANT SELECT ON "errorLogs" TO bn_ro;

GRANT SELECT ON "errorLogs" TO bn_ro_role;

GRANT SELECT ON "errorLogs" TO bn_ro_user1;

GRANT SELECT ON "errorLogs" TO dejan_user;

