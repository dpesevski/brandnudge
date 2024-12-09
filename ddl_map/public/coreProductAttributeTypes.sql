CREATE TABLE "coreProductAttributeTypes"
(
    "keyName"      varchar(255)                           NOT NULL
        PRIMARY KEY,
    "keyValue"     text,
    "valueType"    "enum_coreProductAttributeTypes_valueType",
    "valueOptions" json,
    "createdAt"    timestamp with time zone DEFAULT NOW() NOT NULL,
    "updatedAt"    timestamp with time zone DEFAULT NOW() NOT NULL
);

ALTER TABLE "coreProductAttributeTypes"
    OWNER TO postgres;

GRANT SELECT ON "coreProductAttributeTypes" TO bn_ro;

GRANT SELECT ON "coreProductAttributeTypes" TO dejan_user;

