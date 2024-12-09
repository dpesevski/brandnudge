CREATE TABLE "coreRetailerSources"
(
    id               serial
        PRIMARY KEY,
    "coreRetailerId" integer,
    "retailerId"     integer,
    "sourceId"       varchar(255),
    "createdAt"      timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"      timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    load_id          integer,
    CONSTRAINT coreretailersources_pk
        UNIQUE ("retailerId", "sourceId"),
    CONSTRAINT coreretailersources_coreretailers_id_retailerid_fk
        FOREIGN KEY ("coreRetailerId", "retailerId") REFERENCES "coreRetailers" (id, "retailerId")
);

ALTER TABLE "coreRetailerSources"
    OWNER TO postgres;

GRANT SELECT ON "coreRetailerSources" TO bn_ro;

GRANT SELECT ON "coreRetailerSources" TO dejan_user;

