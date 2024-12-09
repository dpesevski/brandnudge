CREATE TABLE "coreRetailers"
(
    id              serial
        PRIMARY KEY,
    "coreProductId" integer,
    "retailerId"    integer,
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    load_id         integer,
    CONSTRAINT coreretailers_pk
        UNIQUE ("coreProductId", "retailerId"),
    CONSTRAINT coreretailers_pk2
        UNIQUE (id, "retailerId")
);

ALTER TABLE "coreRetailers"
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON coreretailers_pk2 TO postgres;

GRANT SELECT ON coreretailers_pk2 TO bn_ro;

GRANT SELECT ON coreretailers_pk2 TO bn_ro_role;

GRANT SELECT ON coreretailers_pk2 TO bn_ro_user1;

GRANT SELECT ON coreretailers_pk2 TO dejan_user;

GRANT SELECT ON "coreRetailers" TO bn_ro;

GRANT SELECT ON "coreRetailers" TO bn_ro_role;

GRANT SELECT ON "coreRetailers" TO bn_ro_user1;

GRANT SELECT ON "coreRetailers" TO dejan_user;

