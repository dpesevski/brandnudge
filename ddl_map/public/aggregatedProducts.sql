CREATE TABLE "aggregatedProducts"
(
    id            integer      DEFAULT NEXTVAL('"aggregatedProducts_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    "titleMatch"  varchar(255),
    "productId"   integer
        REFERENCES products,
    "createdAt"   timestamp with time zone                                              NOT NULL,
    "updatedAt"   timestamp with time zone                                              NOT NULL,
    features      varchar(255),
    specification varchar(255) DEFAULT '0'::character varying,
    size          varchar(255) DEFAULT '0'::character varying,
    description   varchar(255) DEFAULT '0'::character varying,
    ingredients   varchar(255) DEFAULT '0'::character varying,
    "imageMatch"  varchar(255) DEFAULT '0'::character varying,
    load_id       integer
);

ALTER TABLE "aggregatedProducts"
    OWNER TO postgres;

CREATE INDEX "IND_AGG_PRODUCTS_PRODUCT_ID"
    ON "aggregatedProducts" ("productId");

CREATE UNIQUE INDEX aggregatedproducts_uq_key
    ON "aggregatedProducts" ("productId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT SELECT ON "aggregatedProducts" TO bn_ro;

GRANT SELECT ON "aggregatedProducts" TO bn_ro_role;

GRANT SELECT ON "aggregatedProducts" TO bn_ro_user1;

GRANT SELECT ON "aggregatedProducts" TO dejan_user;

