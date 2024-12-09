CREATE TABLE data_corr.data_corr_affected_reviews
(
    id                   integer,
    "coreRetailerId"     integer,
    "reviewId"           text,
    title                text,
    comment              text,
    rating               integer,
    date                 timestamp with time zone,
    "createdAt"          timestamp with time zone,
    "updatedAt"          timestamp with time zone,
    "new_coreRetailerId" integer
);

ALTER TABLE data_corr.data_corr_affected_reviews
    OWNER TO postgres;

GRANT SELECT ON data_corr.data_corr_affected_reviews TO bn_ro;

GRANT SELECT ON data_corr.data_corr_affected_reviews TO dejan_user;

