CREATE TABLE retailers
(
    id          integer      DEFAULT NEXTVAL('retailers_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    name        varchar(255),
    "createdAt" timestamp with time zone                                   NOT NULL,
    "updatedAt" timestamp with time zone                                   NOT NULL,
    color       varchar(255) DEFAULT '#ffffff'::character varying          NOT NULL,
    logo        varchar(255),
    "countryId" integer
        REFERENCES countries,
    load_id     integer,
    CONSTRAINT retailer_country_unique
        UNIQUE (name, "countryId")
);

ALTER TABLE retailers
    OWNER TO postgres;

GRANT SELECT ON retailers TO bn_ro;

GRANT SELECT ON retailers TO bn_ro_role;

GRANT SELECT ON retailers TO bn_ro_user1;

GRANT SELECT ON retailers TO dejan_user;

