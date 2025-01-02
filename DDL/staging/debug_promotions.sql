CREATE TABLE STAGING.DEBUG_PROMOTIONS
(
    ID                    integer                  NOT NULL,
    "retailerPromotionId" integer                  NOT NULL,
    "productId"           integer                  NOT NULL,
    DESCRIPTION           text                     NOT NULL,
    "startDate"           varchar(255),
    "endDate"             varchar(255),
    "createdAt"           timestamp with time zone NOT NULL,
    "updatedAt"           timestamp with time zone NOT NULL,
    "promoId"             text,
    LOAD_ID               integer
);

ALTER TABLE STAGING.DEBUG_PROMOTIONS
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_PROMOTIONS TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_PROMOTIONS TO DEJAN_USER;

