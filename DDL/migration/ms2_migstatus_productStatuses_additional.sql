CREATE TABLE MIGRATION."ms2_migstatus_productStatuses_additional"
(
    "productId"     integer,
    ID              integer,
    STATUS          varchar(255),
    SCREENSHOT      varchar(255),
    "createdAt"     timestamp with time zone,
    "updatedAt"     timestamp with time zone,
    LOAD_ID         integer,
    "retailerId"    integer,
    "coreProductId" integer,
    DATE            date
);

ALTER TABLE MIGRATION."ms2_migstatus_productStatuses_additional"
    OWNER TO POSTGRES;

CREATE UNIQUE INDEX MS2_MIGSTATUS_PRODUCTSTATUSES_ADDITIONAL_PRODUCTID_UINDEX
    ON MIGRATION."ms2_migstatus_productStatuses_additional" ("productId");

CREATE INDEX MS2_MIGSTATUS_PRODUCTSTATUSES_ADDITIONAL_PRODUCTID_ADDINDEX
    ON MIGRATION."ms2_migstatus_productStatuses_additional" ("retailerId", "coreProductId", DATE);

CREATE INDEX MS2_MIGSTATUS_PRODUCTSTATUSES_ADDITIONAL_PRODUCTID_STATUSINDEX
    ON MIGRATION."ms2_migstatus_productStatuses_additional" (STATUS);

GRANT SELECT ON MIGRATION."ms2_migstatus_productStatuses_additional" TO BN_RO;

GRANT SELECT ON MIGRATION."ms2_migstatus_productStatuses_additional" TO DEJAN_USER;

