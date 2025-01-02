CREATE TABLE "SequelizeMeta"
(
    NAME varchar(255) NOT NULL
        PRIMARY KEY
);

ALTER TABLE "SequelizeMeta"
    OWNER TO POSTGRES;

GRANT SELECT ON "SequelizeMeta" TO BN_RO;

GRANT SELECT ON "SequelizeMeta" TO BN_RO_ROLE;

GRANT SELECT ON "SequelizeMeta" TO BN_RO_USER1;

GRANT SELECT ON "SequelizeMeta" TO DEJAN_USER;

