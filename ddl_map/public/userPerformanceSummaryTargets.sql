CREATE TABLE "userPerformanceSummaryTargets"
(
    id          serial
        PRIMARY KEY,
    "userId"    integer                  NOT NULL,
    metric      varchar(255)             NOT NULL,
    "parentId"  integer,
    min         integer DEFAULT 60,
    max         integer DEFAULT 80,
    additional  jsonb,
    common      boolean DEFAULT TRUE     NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userPerformanceSummaryTargets"
    OWNER TO postgres;

GRANT SELECT ON "userPerformanceSummaryTargets" TO bn_ro;

GRANT SELECT ON "userPerformanceSummaryTargets" TO bn_ro_role;

GRANT SELECT ON "userPerformanceSummaryTargets" TO bn_ro_user1;

GRANT SELECT ON "userPerformanceSummaryTargets" TO dejan_user;

