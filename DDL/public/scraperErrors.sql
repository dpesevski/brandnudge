CREATE TABLE "scraperErrors"
(
    ID           serial
        PRIMARY KEY,
    "retailerId" integer                  NOT NULL,
    TYPE         varchar(255)             NOT NULL,
    MESSAGE      text                     NOT NULL,
    URL          text                     NOT NULL,
    RESOLVED     boolean DEFAULT FALSE,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "scraperErrors"
    OWNER TO POSTGRES;

GRANT SELECT ON "scraperErrors" TO BN_RO;

GRANT SELECT ON "scraperErrors" TO BN_RO_ROLE;

GRANT SELECT ON "scraperErrors" TO BN_RO_USER1;

GRANT SELECT ON "scraperErrors" TO DEJAN_USER;

