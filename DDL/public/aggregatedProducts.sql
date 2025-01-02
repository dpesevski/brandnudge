CREATE TABLE "aggregatedProducts"
(
    ID            integer      DEFAULT NEXTVAL('"aggregatedProducts_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    "titleMatch"  varchar(255),
    "productId"   integer
        REFERENCES PRODUCTS,
    "createdAt"   timestamp with time zone                                              NOT NULL,
    "updatedAt"   timestamp with time zone                                              NOT NULL,
    FEATURES      varchar(255),
    SPECIFICATION varchar(255) DEFAULT '0'::character varying,
    SIZE          varchar(255) DEFAULT '0'::character varying,
    DESCRIPTION   varchar(255) DEFAULT '0'::character varying,
    INGREDIENTS   varchar(255) DEFAULT '0'::character varying,
    "imageMatch"  varchar(255) DEFAULT '0'::character varying,
    LOAD_ID       integer
);

ALTER TABLE "aggregatedProducts"
    OWNER TO POSTGRES;

CREATE INDEX "IND_AGG_PRODUCTS_PRODUCT_ID"
    ON "aggregatedProducts" ("productId");

CREATE UNIQUE INDEX AGGREGATEDPRODUCTS_UQ_KEY
    ON "aggregatedProducts" ("productId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT SELECT ON "aggregatedProducts" TO BN_RO;

GRANT SELECT ON "aggregatedProducts" TO BN_RO_ROLE;

GRANT SELECT ON "aggregatedProducts" TO BN_RO_USER1;

GRANT SELECT ON "aggregatedProducts" TO DEJAN_USER;

