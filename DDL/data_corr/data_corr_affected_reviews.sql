CREATE TABLE DATA_CORR.DATA_CORR_AFFECTED_REVIEWS
(
    ID                   integer,
    "coreRetailerId"     integer,
    "reviewId"           text,
    TITLE                text,
    COMMENT              text,
    RATING               integer,
    DATE                 timestamp with time zone,
    "createdAt"          timestamp with time zone,
    "updatedAt"          timestamp with time zone,
    "new_coreRetailerId" integer
);

ALTER TABLE DATA_CORR.DATA_CORR_AFFECTED_REVIEWS
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR.DATA_CORR_AFFECTED_REVIEWS TO BN_RO;

GRANT SELECT ON DATA_CORR.DATA_CORR_AFFECTED_REVIEWS TO DEJAN_USER;

