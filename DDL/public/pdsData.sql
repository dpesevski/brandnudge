CREATE TABLE "pdsData"
(
    ID          integer DEFAULT NEXTVAL('"pdsData_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    DATE        timestamp with time zone,
    SUM         numeric(12, 2),
    UNITS       integer,
    TYPE        varchar(255),
    "createdAt" timestamp with time zone                              NOT NULL,
    "updatedAt" timestamp with time zone                              NOT NULL,
    "pdsCoreId" integer                                               NOT NULL
        REFERENCES "pdsCores"
);

ALTER TABLE "pdsData"
    OWNER TO POSTGRES;

GRANT SELECT ON "pdsData" TO BN_RO;

GRANT SELECT ON "pdsData" TO BN_RO_ROLE;

GRANT SELECT ON "pdsData" TO BN_RO_USER1;

GRANT SELECT ON "pdsData" TO DEJAN_USER;

