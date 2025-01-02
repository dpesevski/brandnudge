CREATE TABLE "productsCleanUpStatuses"
(
    ID               serial
        PRIMARY KEY,
    "retailerId"     integer                                       NOT NULL
        REFERENCES RETAILERS,
    "retailerName"   varchar(255)                                  NOT NULL,
    "dateId"         integer                                       NOT NULL
        REFERENCES DATES,
    DATE             timestamp with time zone                      NOT NULL,
    STATUS           varchar(255) DEFAULT 'new'::character varying NOT NULL,
    "productsCount"  integer,
    "completedCount" integer,
    "createdAt"      timestamp with time zone                      NOT NULL,
    "updatedAt"      timestamp with time zone                      NOT NULL
);

ALTER TABLE "productsCleanUpStatuses"
    OWNER TO POSTGRES;

GRANT SELECT ON "productsCleanUpStatuses" TO BN_RO;

GRANT SELECT ON "productsCleanUpStatuses" TO DEJAN_USER;

