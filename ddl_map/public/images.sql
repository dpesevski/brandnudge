CREATE TABLE images
(
    id              integer DEFAULT NEXTVAL('images_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    score           varchar(255),
    "ressemblePath" text,
    "originalPath"  text,
    "createdAt"     timestamp with time zone                           NOT NULL,
    "updatedAt"     timestamp with time zone                           NOT NULL,
    "modifiedPath"  text,
    "diffImage"     text
);

ALTER TABLE images
    OWNER TO postgres;

CREATE INDEX "images_originalPath"
    ON images ("originalPath");

GRANT SELECT ON images TO bn_ro;

GRANT SELECT ON images TO bn_ro_role;

GRANT SELECT ON images TO bn_ro_user1;

GRANT SELECT ON images TO dejan_user;

