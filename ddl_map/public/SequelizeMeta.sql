CREATE TABLE "SequelizeMeta"
(
    name varchar(255) NOT NULL
        PRIMARY KEY
);

ALTER TABLE "SequelizeMeta"
    OWNER TO postgres;

GRANT SELECT ON "SequelizeMeta" TO bn_ro;

GRANT SELECT ON "SequelizeMeta" TO bn_ro_role;

GRANT SELECT ON "SequelizeMeta" TO bn_ro_user1;

GRANT SELECT ON "SequelizeMeta" TO dejan_user;

