CREATE TABLE "oneTimeCodes"
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES USERS
            ON DELETE CASCADE,
    CODE        varchar(255),
    TYPE        varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "oneTimeCodes"
    OWNER TO POSTGRES;

GRANT SELECT ON "oneTimeCodes" TO BN_RO;

GRANT SELECT ON "oneTimeCodes" TO BN_RO_ROLE;

GRANT SELECT ON "oneTimeCodes" TO BN_RO_USER1;

GRANT SELECT ON "oneTimeCodes" TO DEJAN_USER;

