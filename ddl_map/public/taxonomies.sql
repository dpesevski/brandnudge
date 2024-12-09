CREATE TABLE taxonomies
(
    id              integer DEFAULT NEXTVAL('taxonomies_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    level           integer,
    category        varchar(255),
    retailer        varchar(255),
    "taxonomyId"    integer
        REFERENCES taxonomies,
    "createdAt"     timestamp with time zone                               NOT NULL,
    "updatedAt"     timestamp with time zone                               NOT NULL,
    date            timestamp with time zone,
    position        integer,
    "productsCount" integer
);

ALTER TABLE taxonomies
    OWNER TO postgres;

GRANT SELECT ON taxonomies TO bn_ro;

GRANT SELECT ON taxonomies TO bn_ro_role;

GRANT SELECT ON taxonomies TO bn_ro_user1;

GRANT SELECT ON taxonomies TO dejan_user;

