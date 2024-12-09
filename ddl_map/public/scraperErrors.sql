CREATE TABLE "scraperErrors"
(
    id           serial
        PRIMARY KEY,
    "retailerId" integer                  NOT NULL,
    type         varchar(255)             NOT NULL,
    message      text                     NOT NULL,
    url          text                     NOT NULL,
    resolved     boolean DEFAULT FALSE,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "scraperErrors"
    OWNER TO postgres;

GRANT SELECT ON "scraperErrors" TO bn_ro;

GRANT SELECT ON "scraperErrors" TO bn_ro_role;

GRANT SELECT ON "scraperErrors" TO bn_ro_user1;

GRANT SELECT ON "scraperErrors" TO dejan_user;

