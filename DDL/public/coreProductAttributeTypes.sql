CREATE TABLE "coreProductAttributeTypes"
(
    "keyName"      varchar(255)                           NOT NULL
        PRIMARY KEY,
    "keyValue"     text,
    "valueType"    "enum_coreProductAttributeTypes_valueType",
    "valueOptions" JSON,
    "createdAt"    timestamp with time zone DEFAULT NOW() NOT NULL,
    "updatedAt"    timestamp with time zone DEFAULT NOW() NOT NULL
);

ALTER TABLE "coreProductAttributeTypes"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreProductAttributeTypes" TO BN_RO;

GRANT SELECT ON "coreProductAttributeTypes" TO DEJAN_USER;

