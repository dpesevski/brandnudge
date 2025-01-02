CREATE TABLE RETAILERS
(
    ID          integer      DEFAULT NEXTVAL('retailers_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME        varchar(255),
    "createdAt" timestamp with time zone                                   NOT NULL,
    "updatedAt" timestamp with time zone                                   NOT NULL,
    COLOR       varchar(255) DEFAULT '#ffffff'::character varying          NOT NULL,
    LOGO        varchar(255),
    "countryId" integer
        REFERENCES COUNTRIES,
    LOAD_ID     integer,
    CONSTRAINT RETAILER_COUNTRY_UNIQUE
        UNIQUE (NAME, "countryId")
);

ALTER TABLE RETAILERS
    OWNER TO POSTGRES;

GRANT SELECT ON RETAILERS TO BN_RO;

GRANT SELECT ON RETAILERS TO BN_RO_ROLE;

GRANT SELECT ON RETAILERS TO BN_RO_USER1;

GRANT SELECT ON RETAILERS TO DEJAN_USER;

