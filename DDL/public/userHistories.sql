CREATE TABLE "userHistories"
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer,
    PATH        text,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userHistories"
    OWNER TO POSTGRES;

GRANT SELECT ON "userHistories" TO BN_RO;

GRANT SELECT ON "userHistories" TO BN_RO_ROLE;

GRANT SELECT ON "userHistories" TO BN_RO_USER1;

GRANT SELECT ON "userHistories" TO DEJAN_USER;

