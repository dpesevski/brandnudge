CREATE TABLE "productGroups"
(
    ID          integer      DEFAULT NEXTVAL('"productGroups_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME        varchar(255),
    "createdAt" timestamp with time zone                                         NOT NULL,
    "updatedAt" timestamp with time zone                                         NOT NULL,
    "userId"    integer
        REFERENCES USERS,
    "companyId" integer
        REFERENCES COMPANIES,
    COLOR       varchar(255) DEFAULT '#ffffff'::character varying                NOT NULL
);

ALTER TABLE "productGroups"
    OWNER TO POSTGRES;

GRANT SELECT ON "productGroups" TO BN_RO;

GRANT SELECT ON "productGroups" TO BN_RO_ROLE;

GRANT SELECT ON "productGroups" TO BN_RO_USER1;

GRANT SELECT ON "productGroups" TO DEJAN_USER;

