CREATE TABLE banners
(
    id             integer DEFAULT NEXTVAL('banners_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    image          text,
    category       varchar(255),
    "retailerId"   integer
        REFERENCES retailers,
    "createdAt"    timestamp with time zone                            NOT NULL,
    "updatedAt"    timestamp with time zone                            NOT NULL,
    "categoryType" varchar(255),
    title          varchar(255),
    screenshot     text,
    "bannerId"     text                                                NOT NULL,
    "startDate"    timestamp with time zone                            NOT NULL,
    "endDate"      timestamp with time zone                            NOT NULL
);

ALTER TABLE banners
    OWNER TO postgres;

CREATE INDEX banners_startdate_index
    ON banners ("startDate");

CREATE INDEX banners_enddate_index
    ON banners ("endDate");

GRANT SELECT ON banners TO bn_ro;

GRANT SELECT ON banners TO bn_ro_role;

GRANT SELECT ON banners TO bn_ro_user1;

GRANT SELECT ON banners TO dejan_user;

