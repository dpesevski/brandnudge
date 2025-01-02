CREATE TABLE CATEGORIES
(
    ID                integer      DEFAULT NEXTVAL('categories_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME              varchar(255)
        CONSTRAINT CATEGORIES_UNIQUE
            UNIQUE,
    "categoryId"      integer
        REFERENCES CATEGORIES,
    "createdAt"       timestamp with time zone                                    NOT NULL,
    "updatedAt"       timestamp with time zone                                    NOT NULL,
    COLOR             varchar(255) DEFAULT '#ffffff'::character varying           NOT NULL,
    "measurementUnit" varchar(255),
    "pricePer"        varchar(255)
);

ALTER TABLE CATEGORIES
    OWNER TO POSTGRES;

CREATE INDEX "IND_CATEGORIES_CATEGORY_ID"
    ON CATEGORIES ("categoryId");

GRANT SELECT ON CATEGORIES TO BN_RO;

GRANT SELECT ON CATEGORIES TO BN_RO_ROLE;

GRANT SELECT ON CATEGORIES TO BN_RO_USER1;

GRANT SELECT ON CATEGORIES TO DEJAN_USER;

