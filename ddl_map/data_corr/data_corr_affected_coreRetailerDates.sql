CREATE TABLE data_corr."data_corr_affected_coreRetailerDates"
(
    id                   integer,
    "coreRetailerId"     integer,
    "dateId"             integer,
    "createdAt"          timestamp with time zone,
    "updatedAt"          timestamp with time zone,
    "new_coreRetailerId" integer
);

ALTER TABLE data_corr."data_corr_affected_coreRetailerDates"
    OWNER TO postgres;

GRANT SELECT ON data_corr."data_corr_affected_coreRetailerDates" TO bn_ro;

GRANT SELECT ON data_corr."data_corr_affected_coreRetailerDates" TO dejan_user;

