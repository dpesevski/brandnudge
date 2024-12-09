CREATE TABLE "taxonomyProducts"
(
    id              integer DEFAULT NEXTVAL('"taxonomyProducts_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    retailer        varchar(255),
    "sourceId"      varchar(255),
    "taxonomyId"    integer                                                        NOT NULL
        REFERENCES taxonomies,
    date            timestamp with time zone                                       NOT NULL,
    "coreProductId" integer                                                        NOT NULL
        REFERENCES "coreProducts",
    "createdAt"     timestamp with time zone                                       NOT NULL,
    "updatedAt"     timestamp with time zone                                       NOT NULL
);

ALTER TABLE "taxonomyProducts"
    OWNER TO postgres;

