CREATE TABLE "sharedReports"
(
    id          serial
        PRIMARY KEY,
    "reportId"  integer                  NOT NULL,
    "userId"    integer                  NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "sharedReports"
    OWNER TO postgres;

GRANT SELECT ON "sharedReports" TO bn_ro;

GRANT SELECT ON "sharedReports" TO bn_ro_role;

GRANT SELECT ON "sharedReports" TO bn_ro_user1;

GRANT SELECT ON "sharedReports" TO dejan_user;

