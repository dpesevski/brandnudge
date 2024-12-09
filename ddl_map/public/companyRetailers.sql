CREATE TABLE "companyRetailers"
(
    id           serial
        PRIMARY KEY,
    "retailerId" integer,
    "companyId"  integer,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "companyRetailers"
    OWNER TO postgres;

GRANT SELECT ON "companyRetailers" TO bn_ro;

GRANT SELECT ON "companyRetailers" TO bn_ro_role;

GRANT SELECT ON "companyRetailers" TO bn_ro_user1;

GRANT SELECT ON "companyRetailers" TO dejan_user;

