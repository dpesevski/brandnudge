CREATE TABLE "userPerformanceSummaryTargets"
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer                  NOT NULL,
    METRIC      varchar(255)             NOT NULL,
    "parentId"  integer,
    MIN         integer DEFAULT 60,
    MAX         integer DEFAULT 80,
    ADDITIONAL  JSONB,
    COMMON      boolean DEFAULT TRUE     NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userPerformanceSummaryTargets"
    OWNER TO POSTGRES;

GRANT SELECT ON "userPerformanceSummaryTargets" TO BN_RO;

GRANT SELECT ON "userPerformanceSummaryTargets" TO BN_RO_ROLE;

GRANT SELECT ON "userPerformanceSummaryTargets" TO BN_RO_USER1;

GRANT SELECT ON "userPerformanceSummaryTargets" TO DEJAN_USER;

