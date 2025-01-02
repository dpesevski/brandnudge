CREATE TABLE "productStatuses"
(
    ID          serial
        PRIMARY KEY,
    "productId" integer
        CONSTRAINT "productStatuses_productId_uq"
            UNIQUE
        CONSTRAINT PRODUCTSTATUSES_PRODUCTS_ID_FK
            REFERENCES PRODUCTS,
    STATUS      varchar(255) DEFAULT 'listed'::character varying NOT NULL,
    SCREENSHOT  varchar(255),
    "createdAt" timestamp with time zone                         NOT NULL,
    "updatedAt" timestamp with time zone                         NOT NULL,
    LOAD_ID     integer
);

ALTER TABLE "productStatuses"
    OWNER TO POSTGRES;

GRANT SELECT ON "productStatuses" TO BN_RO;

GRANT SELECT ON "productStatuses" TO BN_RO_ROLE;

GRANT SELECT ON "productStatuses" TO BN_RO_USER1;

GRANT SELECT ON "productStatuses" TO DEJAN_USER;

