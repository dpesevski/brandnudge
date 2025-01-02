CREATE TABLE NOTIFICATIONS
(
    ID               serial
        PRIMARY KEY,
    "userId"         integer,
    MESSAGE          text,
    STATUS           boolean,
    "scraperErrorId" integer,
    "productErrorId" integer,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE NOTIFICATIONS
    OWNER TO POSTGRES;

GRANT SELECT ON NOTIFICATIONS TO BN_RO;

GRANT SELECT ON NOTIFICATIONS TO BN_RO_ROLE;

GRANT SELECT ON NOTIFICATIONS TO BN_RO_USER1;

GRANT SELECT ON NOTIFICATIONS TO DEJAN_USER;

