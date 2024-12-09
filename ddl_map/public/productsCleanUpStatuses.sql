CREATE TABLE "productsCleanUpStatuses"
(
    id               serial
        PRIMARY KEY,
    "retailerId"     integer                                       NOT NULL
        REFERENCES retailers,
    "retailerName"   varchar(255)                                  NOT NULL,
    "dateId"         integer                                       NOT NULL
        REFERENCES dates,
    date             timestamp with time zone                      NOT NULL,
    status           varchar(255) DEFAULT 'new'::character varying NOT NULL,
    "productsCount"  integer,
    "completedCount" integer,
    "createdAt"      timestamp with time zone                      NOT NULL,
    "updatedAt"      timestamp with time zone                      NOT NULL
);

ALTER TABLE "productsCleanUpStatuses"
    OWNER TO postgres;

GRANT SELECT ON "productsCleanUpStatuses" TO bn_ro;

GRANT SELECT ON "productsCleanUpStatuses" TO dejan_user;

