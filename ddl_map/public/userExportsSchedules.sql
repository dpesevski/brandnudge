CREATE TABLE "userExportsSchedules"
(
    id          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES users
            ON DELETE CASCADE,
    name        text,
    schedule    jsonb,
    section     text,
    data        jsonb,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "sectionId" integer,
    emails      jsonb
);

ALTER TABLE "userExportsSchedules"
    OWNER TO postgres;

