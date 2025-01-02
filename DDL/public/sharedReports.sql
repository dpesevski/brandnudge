CREATE TABLE "sharedReports"
(
    ID          serial
        PRIMARY KEY,
    "reportId"  integer                  NOT NULL,
    "userId"    integer                  NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "sharedReports"
    OWNER TO POSTGRES;

GRANT SELECT ON "sharedReports" TO BN_RO;

GRANT SELECT ON "sharedReports" TO BN_RO_ROLE;

GRANT SELECT ON "sharedReports" TO BN_RO_USER1;

GRANT SELECT ON "sharedReports" TO DEJAN_USER;

