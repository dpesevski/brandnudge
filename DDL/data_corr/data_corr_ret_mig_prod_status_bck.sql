CREATE TABLE DATA_CORR.DATA_CORR_RET_MIG_PROD_STATUS_BCK
(
    ID          integer,
    "productId" integer,
    STATUS      varchar(255),
    SCREENSHOT  varchar(255),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    LOAD_ID     integer
);

ALTER TABLE DATA_CORR.DATA_CORR_RET_MIG_PROD_STATUS_BCK
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR.DATA_CORR_RET_MIG_PROD_STATUS_BCK TO BN_RO;

GRANT SELECT ON DATA_CORR.DATA_CORR_RET_MIG_PROD_STATUS_BCK TO DEJAN_USER;

