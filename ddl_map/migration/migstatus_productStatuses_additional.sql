CREATE TABLE migration."migstatus_productStatuses_additional"
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

ALTER TABLE migration."migstatus_productStatuses_additional"
    OWNER TO postgres;

CREATE UNIQUE INDEX migstatus_productstatuses_additional_productid_uindex
    ON migration."migstatus_productStatuses_additional" ("productId");

CREATE INDEX migstatus_productstatuses_additional_productid_addindex
    ON migration."migstatus_productStatuses_additional" ("retailerId", "coreProductId", date);

CREATE INDEX migstatus_productstatuses_additional_productid_statusindex
    ON migration."migstatus_productStatuses_additional" (status);

GRANT SELECT ON migration."migstatus_productStatuses_additional" TO bn_ro;

GRANT SELECT ON migration."migstatus_productStatuses_additional" TO dejan_user;

