CREATE TYPE staging.t_promotion AS
(
    "promoId"             text,
    "retailerPromotionId" integer,
    "startDate"           timestamp,
    "endDate"             timestamp,
    description           text,
    mechanic              text
);

ALTER TYPE staging.t_promotion OWNER TO postgres;

