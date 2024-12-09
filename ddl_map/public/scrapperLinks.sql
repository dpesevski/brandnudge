CREATE TABLE "scrapperLinks"
(
    id             integer DEFAULT NEXTVAL('"scrapperLinks_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    url            varchar(1024),
    category       varchar(255),
    "categoryType" varchar(255),
    retailer       varchar(255),
    "createdAt"    timestamp with time zone                                    NOT NULL,
    "updatedAt"    timestamp with time zone                                    NOT NULL
);

ALTER TABLE "scrapperLinks"
    OWNER TO postgres;

GRANT SELECT ON "scrapperLinks" TO bn_ro;

GRANT SELECT ON "scrapperLinks" TO bn_ro_role;

GRANT SELECT ON "scrapperLinks" TO bn_ro_user1;

GRANT SELECT ON "scrapperLinks" TO dejan_user;

