CREATE TABLE "coreCategoryStatuses"
(
    id               serial
        PRIMARY KEY,
    "coreCategoryId" integer                  NOT NULL,
    subscription     boolean DEFAULT FALSE    NOT NULL,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "coreCategoryStatuses"
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "coreCategoryStatuses_pkey" TO postgres;

GRANT SELECT ON "coreCategoryStatuses_pkey" TO bn_ro;

GRANT SELECT ON "coreCategoryStatuses_pkey" TO bn_ro_role;

GRANT SELECT ON "coreCategoryStatuses_pkey" TO bn_ro_user1;

GRANT SELECT ON "coreCategoryStatuses_pkey" TO dejan_user;

GRANT SELECT ON "coreCategoryStatuses" TO bn_ro;

GRANT SELECT ON "coreCategoryStatuses" TO bn_ro_role;

GRANT SELECT ON "coreCategoryStatuses" TO bn_ro_user1;

GRANT SELECT ON "coreCategoryStatuses" TO dejan_user;

