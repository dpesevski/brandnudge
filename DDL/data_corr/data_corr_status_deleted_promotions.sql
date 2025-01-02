CREATE TABLE DATA_CORR.DATA_CORR_STATUS_DELETED_PROMOTIONS
(
    ID                    integer,
    "retailerPromotionId" integer,
    "productId"           integer,
    DESCRIPTION           text,
    "startDate"           varchar(255),
    "endDate"             varchar(255),
    "createdAt"           timestamp with time zone,
    "updatedAt"           timestamp with time zone,
    "promoId"             text,
    LOAD_ID               integer
);

ALTER TABLE DATA_CORR.DATA_CORR_STATUS_DELETED_PROMOTIONS
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR.DATA_CORR_STATUS_DELETED_PROMOTIONS TO BN_RO;

GRANT SELECT ON DATA_CORR.DATA_CORR_STATUS_DELETED_PROMOTIONS TO DEJAN_USER;

