CREATE TABLE "productErrorProducts"
(
    ID          serial
        PRIMARY KEY,
    "errorId"   integer                  NOT NULL,
    "productId" integer                  NOT NULL,
    RESOLVED    boolean DEFAULT FALSE    NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "productErrorProducts"
    OWNER TO POSTGRES;

GRANT SELECT ON "productErrorProducts" TO BN_RO;

GRANT SELECT ON "productErrorProducts" TO BN_RO_ROLE;

GRANT SELECT ON "productErrorProducts" TO BN_RO_USER1;

GRANT SELECT ON "productErrorProducts" TO DEJAN_USER;

