CREATE TABLE REVIEWS
(
    ID               serial
        PRIMARY KEY,
    "coreRetailerId" integer                  NOT NULL,
    "reviewId"       text,
    TITLE            text,
    COMMENT          text,
    RATING           integer,
    DATE             timestamp with time zone,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE REVIEWS
    OWNER TO POSTGRES;

CREATE INDEX "coreRetailerId_reviewId_index"
    ON REVIEWS ("coreRetailerId", "reviewId");

CREATE UNIQUE INDEX CORERETAILERID_REVIEWID_UNIQ
    ON REVIEWS ("coreRetailerId", "reviewId");

CREATE INDEX REVIEWS_CORERETAILERID_DATE_INDEX
    ON REVIEWS ("coreRetailerId", DATE);

GRANT SELECT ON REVIEWS TO BN_RO;

GRANT SELECT ON REVIEWS TO BN_RO_ROLE;

GRANT SELECT ON REVIEWS TO BN_RO_USER1;

GRANT SELECT ON REVIEWS TO DEJAN_USER;

