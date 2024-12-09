CREATE TABLE staging.debug_coreproductcountrydata
(
    id                       integer                  NOT NULL,
    "coreProductId"          integer,
    "countryId"              integer,
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
    "ownLabelManufacturerId" integer,
    "brandbankManaged"       boolean,
    load_id                  integer
);

ALTER TABLE staging.debug_coreproductcountrydata
    OWNER TO postgres;

GRANT SELECT ON staging.debug_coreproductcountrydata TO bn_ro;

GRANT SELECT ON staging.debug_coreproductcountrydata TO dejan_user;

