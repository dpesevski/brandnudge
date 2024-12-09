CREATE TABLE staging.debug_promotions
(
    id                    integer                  NOT NULL,
    "retailerPromotionId" integer                  NOT NULL,
    "productId"           integer                  NOT NULL,
    description           text                     NOT NULL,
    "startDate"           varchar(255),
    "endDate"             varchar(255),
    "createdAt"           timestamp with time zone NOT NULL,
    "updatedAt"           timestamp with time zone NOT NULL,
    "promoId"             text,
    load_id               integer
);

ALTER TABLE staging.debug_promotions
    OWNER TO postgres;

GRANT SELECT ON staging.debug_promotions TO bn_ro;

GRANT SELECT ON staging.debug_promotions TO dejan_user;

