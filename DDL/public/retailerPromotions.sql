CREATE TABLE "retailerPromotions"
(
    ID                    serial
        PRIMARY KEY,
    "retailerId"          integer                  NOT NULL,
    "promotionMechanicId" integer                  NOT NULL,
    REGEXP                text DEFAULT ''::text    NOT NULL,
    "createdAt"           timestamp with time zone NOT NULL,
    "updatedAt"           timestamp with time zone NOT NULL
);

ALTER TABLE "retailerPromotions"
    OWNER TO POSTGRES;

GRANT SELECT ON "retailerPromotions" TO BN_RO;

GRANT SELECT ON "retailerPromotions" TO BN_RO_ROLE;

GRANT SELECT ON "retailerPromotions" TO BN_RO_USER1;

GRANT SELECT ON "retailerPromotions" TO DEJAN_USER;

