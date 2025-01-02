CREATE TABLE "userSessions"
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES USERS
            ON DELETE CASCADE,
    ACTION      varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userSessions"
    OWNER TO POSTGRES;

GRANT SELECT ON "userSessions" TO BN_RO;

GRANT SELECT ON "userSessions" TO BN_RO_ROLE;

GRANT SELECT ON "userSessions" TO BN_RO_USER1;

GRANT SELECT ON "userSessions" TO DEJAN_USER;

