CREATE TYPE staging.t_promotion_pp AS
(
    promo_id          text,
    promo_type        text,
    promo_description text,
    multibuy_price    text
);

ALTER TYPE staging.t_promotion_pp OWNER TO postgres;

