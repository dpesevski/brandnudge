CREATE TABLE "scraperSettings"
(
    ID           serial
        PRIMARY KEY,
    "retailerId" integer                  NOT NULL
        CONSTRAINT RETAILER_UNIQUE
            UNIQUE,
    SETTINGS     JSON,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "scraperSettings"
    OWNER TO POSTGRES;

GRANT SELECT ON "scraperSettings" TO BN_RO;

GRANT SELECT ON "scraperSettings" TO BN_RO_ROLE;

GRANT SELECT ON "scraperSettings" TO BN_RO_USER1;

GRANT SELECT ON "scraperSettings" TO DEJAN_USER;

