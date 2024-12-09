CREATE TABLE "coreRetailerDates"
(
    id               serial
        PRIMARY KEY,
    "coreRetailerId" integer
        REFERENCES "coreRetailers"
            ON DELETE CASCADE
            DEFERRABLE,
    "dateId"         integer
        REFERENCES dates
            ON DELETE CASCADE,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL,
    load_id          integer,
    UNIQUE ("coreRetailerId", "dateId")
);

ALTER TABLE "coreRetailerDates"
    OWNER TO postgres;

GRANT SELECT ON "coreRetailerDates" TO bn_ro;

GRANT SELECT ON "coreRetailerDates" TO bn_ro_role;

GRANT SELECT ON "coreRetailerDates" TO bn_ro_user1;

GRANT SELECT ON "coreRetailerDates" TO dejan_user;

