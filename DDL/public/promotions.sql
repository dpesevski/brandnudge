CREATE TABLE PROMOTIONS
(
    ID                    serial
        PRIMARY KEY,
    "retailerPromotionId" integer                  NOT NULL,
    "productId"           integer                  NOT NULL
        CONSTRAINT PROMOTIONS_PRODUCTS_ID_FK
            REFERENCES PRODUCTS,
    DESCRIPTION           text DEFAULT ''::text    NOT NULL,
    "startDate"           varchar(255),
    "endDate"             varchar(255),
    "createdAt"           timestamp with time zone NOT NULL,
    "updatedAt"           timestamp with time zone NOT NULL,
    "promoId"             text,
    LOAD_ID               integer
);

ALTER TABLE PROMOTIONS
    OWNER TO POSTGRES;

CREATE INDEX PROMOTIONS_PRODUCTID_INDEX
    ON PROMOTIONS ("productId");

CREATE INDEX PROMOTIONS_PRODUCTID_STARTDATE_ENDDATE_INDEX
    ON PROMOTIONS ("productId", "startDate", "endDate");

CREATE INDEX PROMOTIONS_PROMOID_INDEX
    ON PROMOTIONS ("promoId");

CREATE UNIQUE INDEX PROMOTIONS_UQ_KEY
    ON PROMOTIONS ("productId", "promoId", "retailerPromotionId", DESCRIPTION, "startDate", "endDate")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT SELECT ON PROMOTIONS TO BN_RO;

GRANT SELECT ON PROMOTIONS TO BN_RO_ROLE;

GRANT SELECT ON PROMOTIONS TO BN_RO_USER1;

GRANT SELECT ON PROMOTIONS TO DEJAN_USER;

