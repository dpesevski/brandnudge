CREATE TABLE STAGING.DEBUG_COREPRODUCTS
(
    ID                integer                  NOT NULL,
    EAN               varchar(255),
    TITLE             text,
    IMAGE             text,
    "secondaryImages" boolean,
    DESCRIPTION       text,
    FEATURES          text,
    INGREDIENTS       text,
    "brandId"         integer,
    "categoryId"      integer,
    "productGroupId"  integer,
    "createdAt"       timestamp with time zone NOT NULL,
    "updatedAt"       timestamp with time zone NOT NULL,
    BUNDLED           boolean,
    DISABLED          boolean                  NOT NULL,
    "eanIssues"       boolean                  NOT NULL,
    SPECIFICATION     text,
    SIZE              varchar(255),
    REVIEWED          boolean                  NOT NULL,
    "productOptions"  boolean                  NOT NULL,
    ATTRIBUTES        JSON,
    LOAD_ID           integer
);

ALTER TABLE STAGING.DEBUG_COREPRODUCTS
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_COREPRODUCTS TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_COREPRODUCTS TO DEJAN_USER;

