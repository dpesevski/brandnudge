CREATE TABLE BANNERS
(
    ID             integer DEFAULT NEXTVAL('banners_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    IMAGE          text,
    CATEGORY       varchar(255),
    "retailerId"   integer
        REFERENCES RETAILERS,
    "createdAt"    timestamp with time zone                            NOT NULL,
    "updatedAt"    timestamp with time zone                            NOT NULL,
    "categoryType" varchar(255),
    TITLE          varchar(255),
    SCREENSHOT     text,
    "bannerId"     text                                                NOT NULL,
    "startDate"    timestamp with time zone                            NOT NULL,
    "endDate"      timestamp with time zone                            NOT NULL
);

ALTER TABLE BANNERS
    OWNER TO POSTGRES;

CREATE INDEX BANNERS_STARTDATE_INDEX
    ON BANNERS ("startDate");

CREATE INDEX BANNERS_ENDDATE_INDEX
    ON BANNERS ("endDate");

GRANT SELECT ON BANNERS TO BN_RO;

GRANT SELECT ON BANNERS TO BN_RO_ROLE;

GRANT SELECT ON BANNERS TO BN_RO_USER1;

GRANT SELECT ON BANNERS TO DEJAN_USER;

