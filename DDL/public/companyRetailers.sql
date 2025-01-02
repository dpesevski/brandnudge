CREATE TABLE "companyRetailers"
(
    ID           serial
        PRIMARY KEY,
    "retailerId" integer,
    "companyId"  integer,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "companyRetailers"
    OWNER TO POSTGRES;

GRANT SELECT ON "companyRetailers" TO BN_RO;

GRANT SELECT ON "companyRetailers" TO BN_RO_ROLE;

GRANT SELECT ON "companyRetailers" TO BN_RO_USER1;

GRANT SELECT ON "companyRetailers" TO DEJAN_USER;

