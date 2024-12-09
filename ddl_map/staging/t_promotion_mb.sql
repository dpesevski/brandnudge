CREATE TYPE staging.t_promotion_mb AS
(
    "promoId"             text,
    "retailerPromotionId" integer,
    "startDate"           timestamp,
    "endDate"             timestamp,
    description           text,
    mechanic              text,
    "multibuyPrice"       double precision
);

ALTER TYPE staging.t_promotion_mb OWNER TO postgres;

