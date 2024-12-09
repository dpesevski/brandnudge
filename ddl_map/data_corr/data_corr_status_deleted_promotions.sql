CREATE TABLE data_corr.data_corr_status_deleted_promotions
(
    id                    integer,
    "retailerPromotionId" integer,
    "productId"           integer,
    description           text,
    "startDate"           varchar(255),
    "endDate"             varchar(255),
    "createdAt"           timestamp with time zone,
    "updatedAt"           timestamp with time zone,
    "promoId"             text,
    load_id               integer
);

ALTER TABLE data_corr.data_corr_status_deleted_promotions
    OWNER TO postgres;

GRANT SELECT ON data_corr.data_corr_status_deleted_promotions TO bn_ro;

GRANT SELECT ON data_corr.data_corr_status_deleted_promotions TO dejan_user;

