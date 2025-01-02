CREATE TABLE STAGING.DEBUG_COREPRODUCTCOUNTRYDATA
(
    ID                       integer                  NOT NULL,
    "coreProductId"          integer,
    "countryId"              integer,
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
    "ownLabelManufacturerId" integer,
    "brandbankManaged"       boolean,
    LOAD_ID                  integer
);

ALTER TABLE STAGING.DEBUG_COREPRODUCTCOUNTRYDATA
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_COREPRODUCTCOUNTRYDATA TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_COREPRODUCTCOUNTRYDATA TO DEJAN_USER;

