CREATE TABLE MAPPINGS
(
    ID          integer DEFAULT NEXTVAL('"asinMappings_id_seq"'::REGCLASS) NOT NULL
        CONSTRAINT "asinMappings_pkey"
            PRIMARY KEY,
    EAN         varchar(255)                                               NOT NULL,
    CODE        varchar(255),
    "createdAt" timestamp with time zone                                   NOT NULL,
    "updatedAt" timestamp with time zone                                   NOT NULL,
    RETAILER_ID integer
        CONSTRAINT "mappings_ retailers___fk"
            REFERENCES RETAILERS
);

ALTER TABLE MAPPINGS
    OWNER TO POSTGRES;

GRANT SELECT ON MAPPINGS TO BN_RO;

GRANT SELECT ON MAPPINGS TO BN_RO_ROLE;

GRANT SELECT ON MAPPINGS TO BN_RO_USER1;

GRANT SELECT ON MAPPINGS TO DEJAN_USER;

