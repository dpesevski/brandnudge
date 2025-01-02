CREATE TABLE "productErrors"
(
    ID           serial
        PRIMARY KEY,
    "retailerId" integer                  NOT NULL,
    TYPE         varchar(255)             NOT NULL,
    RESOLVED     boolean DEFAULT FALSE,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "productErrors"
    OWNER TO POSTGRES;

GRANT SELECT ON "productErrors" TO BN_RO;

GRANT SELECT ON "productErrors" TO BN_RO_ROLE;

GRANT SELECT ON "productErrors" TO BN_RO_USER1;

GRANT SELECT ON "productErrors" TO DEJAN_USER;

