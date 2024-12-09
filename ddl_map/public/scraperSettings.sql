CREATE TABLE "scraperSettings"
(
    id           serial
        PRIMARY KEY,
    "retailerId" integer                  NOT NULL
        CONSTRAINT retailer_unique
            UNIQUE,
    settings     json,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "scraperSettings"
    OWNER TO postgres;

GRANT SELECT ON "scraperSettings" TO bn_ro;

GRANT SELECT ON "scraperSettings" TO bn_ro_role;

GRANT SELECT ON "scraperSettings" TO bn_ro_user1;

GRANT SELECT ON "scraperSettings" TO dejan_user;

