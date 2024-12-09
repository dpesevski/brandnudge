CREATE TABLE promotions
(
    id                    serial
        PRIMARY KEY,
    "retailerPromotionId" integer                  NOT NULL,
    "productId"           integer                  NOT NULL
        CONSTRAINT promotions_products_id_fk
            REFERENCES products,
    description           text DEFAULT ''::text    NOT NULL,
    "startDate"           varchar(255),
    "endDate"             varchar(255),
    "createdAt"           timestamp with time zone NOT NULL,
    "updatedAt"           timestamp with time zone NOT NULL,
    "promoId"             text,
    load_id               integer
);

ALTER TABLE promotions
    OWNER TO postgres;

CREATE INDEX promotions_productid_index
    ON promotions ("productId");

CREATE INDEX promotions_productid_startdate_enddate_index
    ON promotions ("productId", "startDate", "endDate");

CREATE INDEX promotions_promoid_index
    ON promotions ("promoId");

CREATE UNIQUE INDEX promotions_uq_key
    ON promotions ("productId", "promoId", "retailerPromotionId", description, "startDate", "endDate")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT SELECT ON promotions TO bn_ro;

GRANT SELECT ON promotions TO bn_ro_role;

GRANT SELECT ON promotions TO bn_ro_user1;

GRANT SELECT ON promotions TO dejan_user;

