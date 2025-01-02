CREATE TYPE STAGING.T_PROMOTION_MB AS
(
    "promoId"             text,
    "retailerPromotionId" integer,
    "startDate"           timestamp,
    "endDate"             timestamp,
    DESCRIPTION           text,
    MECHANIC              text,
    "multibuyPrice"       double precision
);

ALTER TYPE STAGING.T_PROMOTION_MB OWNER TO POSTGRES;

