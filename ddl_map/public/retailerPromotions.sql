CREATE TABLE "retailerPromotions"
(
    id                    serial
        PRIMARY KEY,
    "retailerId"          integer                  NOT NULL,
    "promotionMechanicId" integer                  NOT NULL,
    regexp                text DEFAULT ''::text    NOT NULL,
    "createdAt"           timestamp with time zone NOT NULL,
    "updatedAt"           timestamp with time zone NOT NULL
);

ALTER TABLE "retailerPromotions"
    OWNER TO postgres;

GRANT SELECT ON "retailerPromotions" TO bn_ro;

GRANT SELECT ON "retailerPromotions" TO bn_ro_role;

GRANT SELECT ON "retailerPromotions" TO bn_ro_user1;

GRANT SELECT ON "retailerPromotions" TO dejan_user;

