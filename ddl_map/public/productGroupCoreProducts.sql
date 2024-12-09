CREATE TABLE "productGroupCoreProducts"
(
    id               serial
        PRIMARY KEY,
    "productGroupId" integer
        CONSTRAINT productgroupcoreproducts_productgroups_id_fk
            REFERENCES "productGroups"
            ON DELETE CASCADE,
    "coreProductId"  integer
        CONSTRAINT productgroupcoreproducts_coreproducts_id_fk
            REFERENCES "coreProducts",
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupCoreProducts"
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "productGroupCoreProducts_pkey" TO postgres;

GRANT SELECT ON "productGroupCoreProducts_pkey" TO bn_ro;

GRANT SELECT ON "productGroupCoreProducts_pkey" TO bn_ro_role;

GRANT SELECT ON "productGroupCoreProducts_pkey" TO bn_ro_user1;

GRANT SELECT ON "productGroupCoreProducts_pkey" TO dejan_user;

