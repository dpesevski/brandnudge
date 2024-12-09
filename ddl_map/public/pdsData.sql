CREATE TABLE "pdsData"
(
    id          integer DEFAULT NEXTVAL('"pdsData_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    date        timestamp with time zone,
    sum         numeric(12, 2),
    units       integer,
    type        varchar(255),
    "createdAt" timestamp with time zone                              NOT NULL,
    "updatedAt" timestamp with time zone                              NOT NULL,
    "pdsCoreId" integer                                               NOT NULL
        REFERENCES "pdsCores"
);

ALTER TABLE "pdsData"
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "pdsData_pkey" TO postgres;

GRANT SELECT ON "pdsData_pkey" TO bn_ro;

GRANT SELECT ON "pdsData_pkey" TO bn_ro_role;

GRANT SELECT ON "pdsData_pkey" TO bn_ro_user1;

GRANT SELECT ON "pdsData_pkey" TO dejan_user;

