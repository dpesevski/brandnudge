CREATE TABLE DATA_CORR."data_corr_affected_coreRetailerDates"
(
    ID                   integer,
    "coreRetailerId"     integer,
    "dateId"             integer,
    "createdAt"          timestamp with time zone,
    "updatedAt"          timestamp with time zone,
    "new_coreRetailerId" integer
);

ALTER TABLE DATA_CORR."data_corr_affected_coreRetailerDates"
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR."data_corr_affected_coreRetailerDates" TO BN_RO;

GRANT SELECT ON DATA_CORR."data_corr_affected_coreRetailerDates" TO DEJAN_USER;

