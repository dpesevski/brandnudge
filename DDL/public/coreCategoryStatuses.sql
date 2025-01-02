CREATE TABLE "coreCategoryStatuses"
(
    ID               serial
        PRIMARY KEY,
    "coreCategoryId" integer                  NOT NULL,
    SUBSCRIPTION     boolean DEFAULT FALSE    NOT NULL,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "coreCategoryStatuses"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreCategoryStatuses" TO BN_RO;

GRANT SELECT ON "coreCategoryStatuses" TO BN_RO_ROLE;

GRANT SELECT ON "coreCategoryStatuses" TO BN_RO_USER1;

GRANT SELECT ON "coreCategoryStatuses" TO DEJAN_USER;

