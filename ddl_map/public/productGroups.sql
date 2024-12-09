CREATE TABLE "productGroups"
(
    id          integer      DEFAULT NEXTVAL('"productGroups_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    name        varchar(255),
    "createdAt" timestamp with time zone                                         NOT NULL,
    "updatedAt" timestamp with time zone                                         NOT NULL,
    "userId"    integer
        REFERENCES users,
    "companyId" integer
        REFERENCES companies,
    color       varchar(255) DEFAULT '#ffffff'::character varying                NOT NULL
);

ALTER TABLE "productGroups"
    OWNER TO postgres;

