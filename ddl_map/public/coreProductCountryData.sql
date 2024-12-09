CREATE TABLE "coreProductCountryData"
(
    id                       serial
        PRIMARY KEY,
    "coreProductId"          integer
        REFERENCES "coreProducts",
    "countryId"              integer
        REFERENCES countries,
    title                    text,
    image                    text,
    description              text,
    features                 text,
    ingredients              text,
    specification            text,
    "createdAt"              timestamp with time zone NOT NULL,
    "updatedAt"              timestamp with time zone NOT NULL,
    "secondaryImages"        varchar(255),
    bundled                  boolean,
    disabled                 boolean,
    reviewed                 boolean,
    "ownLabelManufacturerId" integer
        REFERENCES manufacturers,
    "brandbankManaged"       boolean DEFAULT FALSE,
    load_id                  integer
);

ALTER TABLE "coreProductCountryData"
    OWNER TO postgres;

CREATE UNIQUE INDEX coreproductcountrydata_coreproductid_countryid_key
    ON "coreProductCountryData" ("coreProductId", "countryId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "coreProductCountryData_pkey" TO postgres;

GRANT SELECT ON "coreProductCountryData_pkey" TO bn_ro;

GRANT SELECT ON "coreProductCountryData_pkey" TO bn_ro_role;

GRANT SELECT ON "coreProductCountryData_pkey" TO bn_ro_user1;

GRANT SELECT ON "coreProductCountryData_pkey" TO dejan_user;

GRANT SELECT ON "coreProductCountryData" TO bn_ro;

GRANT SELECT ON "coreProductCountryData" TO bn_ro_role;

GRANT SELECT ON "coreProductCountryData" TO bn_ro_user1;

GRANT SELECT ON "coreProductCountryData" TO dejan_user;

