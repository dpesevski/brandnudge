CREATE TABLE IMAGES
(
    ID              integer DEFAULT NEXTVAL('images_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    SCORE           varchar(255),
    "ressemblePath" text,
    "originalPath"  text,
    "createdAt"     timestamp with time zone                           NOT NULL,
    "updatedAt"     timestamp with time zone                           NOT NULL,
    "modifiedPath"  text,
    "diffImage"     text
);

ALTER TABLE IMAGES
    OWNER TO POSTGRES;

CREATE INDEX "images_originalPath"
    ON IMAGES ("originalPath");

GRANT SELECT ON IMAGES TO BN_RO;

GRANT SELECT ON IMAGES TO BN_RO_ROLE;

GRANT SELECT ON IMAGES TO BN_RO_USER1;

GRANT SELECT ON IMAGES TO DEJAN_USER;

