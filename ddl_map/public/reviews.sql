CREATE TABLE reviews
(
    id               serial
        PRIMARY KEY,
    "coreRetailerId" integer                  NOT NULL,
    "reviewId"       text,
    title            text,
    comment          text,
    rating           integer,
    date             timestamp with time zone,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE reviews
    OWNER TO postgres;

CREATE INDEX "coreRetailerId_reviewId_index"
    ON reviews ("coreRetailerId", "reviewId");

CREATE UNIQUE INDEX coreretailerid_reviewid_uniq
    ON reviews ("coreRetailerId", "reviewId");

CREATE INDEX reviews_coreretailerid_date_index
    ON reviews ("coreRetailerId", date);

GRANT SELECT ON reviews TO bn_ro;

GRANT SELECT ON reviews TO bn_ro_role;

GRANT SELECT ON reviews TO bn_ro_user1;

GRANT SELECT ON reviews TO dejan_user;

