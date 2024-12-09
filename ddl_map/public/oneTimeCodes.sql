CREATE TABLE "oneTimeCodes"
(
    id          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES users
            ON DELETE CASCADE,
    code        varchar(255),
    type        varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "oneTimeCodes"
    OWNER TO postgres;

GRANT SELECT ON "oneTimeCodes" TO bn_ro;

GRANT SELECT ON "oneTimeCodes" TO bn_ro_role;

GRANT SELECT ON "oneTimeCodes" TO bn_ro_user1;

GRANT SELECT ON "oneTimeCodes" TO dejan_user;

