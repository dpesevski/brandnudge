CREATE TABLE migration."ms2_migstatus_productStatuses_additional"
(
    "productId"     integer,
    id              integer,
    status          varchar(255),
    screenshot      varchar(255),
    "createdAt"     timestamp with time zone,
    "updatedAt"     timestamp with time zone,
    load_id         integer,
    "retailerId"    integer,
    "coreProductId" integer,
    date            date
);

ALTER TABLE migration."ms2_migstatus_productStatuses_additional"
    OWNER TO postgres;

CREATE UNIQUE INDEX ms2_migstatus_productstatuses_additional_productid_uindex
    ON migration."ms2_migstatus_productStatuses_additional" ("productId");

CREATE INDEX ms2_migstatus_productstatuses_additional_productid_addindex
    ON migration."ms2_migstatus_productStatuses_additional" ("retailerId", "coreProductId", date);

CREATE INDEX ms2_migstatus_productstatuses_additional_productid_statusindex
    ON migration."ms2_migstatus_productStatuses_additional" (status);

GRANT SELECT ON migration."ms2_migstatus_productStatuses_additional" TO bn_ro;

GRANT SELECT ON migration."ms2_migstatus_productStatuses_additional" TO dejan_user;

