CREATE TABLE "userHistories"
(
    id          serial
        PRIMARY KEY,
    "userId"    integer,
    path        text,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userHistories"
    OWNER TO postgres;

GRANT SELECT ON "userHistories" TO bn_ro;

GRANT SELECT ON "userHistories" TO bn_ro_role;

GRANT SELECT ON "userHistories" TO bn_ro_user1;

GRANT SELECT ON "userHistories" TO dejan_user;

