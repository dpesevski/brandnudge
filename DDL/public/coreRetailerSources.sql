CREATE TABLE "coreRetailerSources"
(
    ID               serial
        PRIMARY KEY,
    "coreRetailerId" integer,
    "retailerId"     integer,
    "sourceId"       varchar(255),
    "createdAt"      timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"      timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    LOAD_ID          integer,
    CONSTRAINT CORERETAILERSOURCES_PK
        UNIQUE ("retailerId", "sourceId"),
    CONSTRAINT CORERETAILERSOURCES_CORERETAILERS_ID_RETAILERID_FK
        FOREIGN KEY ("coreRetailerId", "retailerId") REFERENCES "coreRetailers" (ID, "retailerId")
);

ALTER TABLE "coreRetailerSources"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreRetailerSources" TO BN_RO;

GRANT SELECT ON "coreRetailerSources" TO DEJAN_USER;

