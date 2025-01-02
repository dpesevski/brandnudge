CREATE TABLE "productGroupCoreProducts"
(
    ID               serial
        PRIMARY KEY,
    "productGroupId" integer
        CONSTRAINT PRODUCTGROUPCOREPRODUCTS_PRODUCTGROUPS_ID_FK
            REFERENCES "productGroups"
            ON DELETE CASCADE,
    "coreProductId"  integer
        CONSTRAINT PRODUCTGROUPCOREPRODUCTS_COREPRODUCTS_ID_FK
            REFERENCES "coreProducts",
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupCoreProducts"
    OWNER TO POSTGRES;

GRANT SELECT ON "productGroupCoreProducts" TO BN_RO;

GRANT SELECT ON "productGroupCoreProducts" TO BN_RO_ROLE;

GRANT SELECT ON "productGroupCoreProducts" TO BN_RO_USER1;

GRANT SELECT ON "productGroupCoreProducts" TO DEJAN_USER;

