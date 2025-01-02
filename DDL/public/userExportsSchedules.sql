CREATE TABLE "userExportsSchedules"
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES USERS
            ON DELETE CASCADE,
    NAME        text,
    SCHEDULE    JSONB,
    SECTION     text,
    DATA        JSONB,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "sectionId" integer,
    EMAILS      JSONB
);

ALTER TABLE "userExportsSchedules"
    OWNER TO POSTGRES;

GRANT SELECT ON "userExportsSchedules" TO BN_RO;

GRANT SELECT ON "userExportsSchedules" TO BN_RO_ROLE;

GRANT SELECT ON "userExportsSchedules" TO BN_RO_USER1;

GRANT SELECT ON "userExportsSchedules" TO DEJAN_USER;

