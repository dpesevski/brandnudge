CREATE TABLE "userSessions"
(
    id          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES users
            ON DELETE CASCADE,
    action      varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userSessions"
    OWNER TO postgres;

GRANT SELECT ON "userSessions" TO bn_ro;

GRANT SELECT ON "userSessions" TO bn_ro_role;

GRANT SELECT ON "userSessions" TO bn_ro_user1;

GRANT SELECT ON "userSessions" TO dejan_user;

