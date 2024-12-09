CREATE TABLE "productStatuses"
(
    id          serial
        PRIMARY KEY,
    "productId" integer
        CONSTRAINT "productStatuses_productId_uq"
            UNIQUE
        CONSTRAINT productstatuses_products_id_fk
            REFERENCES products,
    status      varchar(255) DEFAULT 'listed'::character varying NOT NULL,
    screenshot  varchar(255),
    "createdAt" timestamp with time zone                         NOT NULL,
    "updatedAt" timestamp with time zone                         NOT NULL,
    load_id     integer
);

ALTER TABLE "productStatuses"
    OWNER TO postgres;

GRANT SELECT ON "productStatuses" TO bn_ro;

GRANT SELECT ON "productStatuses" TO bn_ro_role;

GRANT SELECT ON "productStatuses" TO bn_ro_user1;

GRANT SELECT ON "productStatuses" TO dejan_user;

