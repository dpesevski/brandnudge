CREATE TABLE "promotionMechanics"
(
    ID          serial
        PRIMARY KEY,
    NAME        varchar(255)             NOT NULL
        CONSTRAINT RETAILER_MECHANIC_UNIQUE
            UNIQUE,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "promotionMechanics"
    OWNER TO POSTGRES;

GRANT SELECT ON "promotionMechanics" TO BN_RO;

GRANT SELECT ON "promotionMechanics" TO BN_RO_ROLE;

GRANT SELECT ON "promotionMechanics" TO BN_RO_USER1;

GRANT SELECT ON "promotionMechanics" TO DEJAN_USER;

