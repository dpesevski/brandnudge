CREATE TYPE STAGING.T_PROMOTION AS
(
    "promoId"             text,
    "retailerPromotionId" integer,
    "startDate"           timestamp,
    "endDate"             timestamp,
    DESCRIPTION           text,
    MECHANIC              text
);

ALTER TYPE STAGING.T_PROMOTION OWNER TO POSTGRES;

