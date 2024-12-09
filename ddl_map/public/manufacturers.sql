CREATE TABLE manufacturers
(
    id                       integer      DEFAULT NEXTVAL('manufacturers_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    name                     varchar(255)
        CONSTRAINT manufacturers_unique
            UNIQUE,
    "createdAt"              timestamp with time zone                                       NOT NULL,
    "updatedAt"              timestamp with time zone                                       NOT NULL,
    color                    varchar(255) DEFAULT '#ffffff'::character varying              NOT NULL,
    "isOwnLabelManufacturer" boolean      DEFAULT FALSE
);

ALTER TABLE manufacturers
    OWNER TO postgres;

