CREATE TABLE "ingestStatuses"
(
    id          serial
        PRIMARY KEY,
    endpoint    varchar(255),
    status      varchar(255) DEFAULT 'running'::character varying NOT NULL,
    "createdAt" timestamp with time zone                          NOT NULL,
    "updatedAt" timestamp with time zone                          NOT NULL,
    retailer    varchar(255)
);

ALTER TABLE "ingestStatuses"
    OWNER TO postgres;

GRANT SELECT ON "ingestStatuses" TO bn_ro;

GRANT SELECT ON "ingestStatuses" TO bn_ro_role;

GRANT SELECT ON "ingestStatuses" TO bn_ro_user1;

GRANT SELECT ON "ingestStatuses" TO dejan_user;

