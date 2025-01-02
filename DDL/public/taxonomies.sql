CREATE TABLE TAXONOMIES
(
    ID              integer DEFAULT NEXTVAL('taxonomies_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    LEVEL           integer,
    CATEGORY        varchar(255),
    RETAILER        varchar(255),
    "taxonomyId"    integer
        REFERENCES TAXONOMIES,
    "createdAt"     timestamp with time zone                               NOT NULL,
    "updatedAt"     timestamp with time zone                               NOT NULL,
    DATE            timestamp with time zone,
    POSITION        integer,
    "productsCount" integer
);

ALTER TABLE TAXONOMIES
    OWNER TO POSTGRES;

GRANT SELECT ON TAXONOMIES TO BN_RO;

GRANT SELECT ON TAXONOMIES TO BN_RO_ROLE;

GRANT SELECT ON TAXONOMIES TO BN_RO_USER1;

GRANT SELECT ON TAXONOMIES TO DEJAN_USER;

