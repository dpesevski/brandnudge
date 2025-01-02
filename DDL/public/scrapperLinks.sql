CREATE TABLE "scrapperLinks"
(
    ID             integer DEFAULT NEXTVAL('"scrapperLinks_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    URL            varchar(1024),
    CATEGORY       varchar(255),
    "categoryType" varchar(255),
    RETAILER       varchar(255),
    "createdAt"    timestamp with time zone                                    NOT NULL,
    "updatedAt"    timestamp with time zone                                    NOT NULL
);

ALTER TABLE "scrapperLinks"
    OWNER TO POSTGRES;

GRANT SELECT ON "scrapperLinks" TO BN_RO;

GRANT SELECT ON "scrapperLinks" TO BN_RO_ROLE;

GRANT SELECT ON "scrapperLinks" TO BN_RO_USER1;

GRANT SELECT ON "scrapperLinks" TO DEJAN_USER;

