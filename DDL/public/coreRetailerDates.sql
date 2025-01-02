CREATE TABLE "coreRetailerDates"
(
    ID               serial
        PRIMARY KEY,
    "coreRetailerId" integer
        REFERENCES "coreRetailers"
            ON DELETE CASCADE
            DEFERRABLE,
    "dateId"         integer
        REFERENCES DATES
            ON DELETE CASCADE,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL,
    LOAD_ID          integer,
    UNIQUE ("coreRetailerId", "dateId")
);

ALTER TABLE "coreRetailerDates"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreRetailerDates" TO BN_RO;

GRANT SELECT ON "coreRetailerDates" TO BN_RO_ROLE;

GRANT SELECT ON "coreRetailerDates" TO BN_RO_USER1;

GRANT SELECT ON "coreRetailerDates" TO DEJAN_USER;

