CREATE TABLE "coreProductCountryData"
(
    ID                       serial
        PRIMARY KEY,
    "coreProductId"          integer
        REFERENCES "coreProducts",
    "countryId"              integer
        REFERENCES COUNTRIES,
    TITLE                    text,
    IMAGE                    text,
    DESCRIPTION              text,
    FEATURES                 text,
    INGREDIENTS              text,
    SPECIFICATION            text,
    "createdAt"              timestamp with time zone NOT NULL,
    "updatedAt"              timestamp with time zone NOT NULL,
    "secondaryImages"        varchar(255),
    BUNDLED                  boolean,
    DISABLED                 boolean,
    REVIEWED                 boolean,
    "ownLabelManufacturerId" integer
        REFERENCES MANUFACTURERS,
    "brandbankManaged"       boolean DEFAULT FALSE,
    LOAD_ID                  integer
);

ALTER TABLE "coreProductCountryData"
    OWNER TO POSTGRES;

CREATE UNIQUE INDEX COREPRODUCTCOUNTRYDATA_COREPRODUCTID_COUNTRYID_KEY
    ON "coreProductCountryData" ("coreProductId", "countryId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT SELECT ON "coreProductCountryData" TO BN_RO;

GRANT SELECT ON "coreProductCountryData" TO BN_RO_ROLE;

GRANT SELECT ON "coreProductCountryData" TO BN_RO_USER1;

GRANT SELECT ON "coreProductCountryData" TO DEJAN_USER;

