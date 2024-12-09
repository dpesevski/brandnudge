CREATE TABLE "promotionMechanics"
(
    id          serial
        PRIMARY KEY,
    name        varchar(255)             NOT NULL
        CONSTRAINT retailer_mechanic_unique
            UNIQUE,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "promotionMechanics"
    OWNER TO postgres;

GRANT SELECT ON "promotionMechanics" TO bn_ro;

GRANT SELECT ON "promotionMechanics" TO bn_ro_role;

GRANT SELECT ON "promotionMechanics" TO bn_ro_user1;

GRANT SELECT ON "promotionMechanics" TO dejan_user;

