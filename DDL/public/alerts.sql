CREATE TABLE ALERTS
(
    ID             serial
        PRIMARY KEY,
    NAME           varchar(255),
    "userId"       integer
        REFERENCES USERS,
    SCHEDULE       JSONB,
    FILTERS        JSONB,
    PRICING        JSONB,
    PROMOTION      JSONB,
    AVAILABILITY   JSONB,
    LISTING        JSONB,
    SMS            boolean,
    "whatsApp"     boolean,
    "createdAt"    timestamp with time zone NOT NULL,
    "updatedAt"    timestamp with time zone NOT NULL,
    MESSAGE        text  DEFAULT ''::text,
    EMAILS         JSONB DEFAULT '[]'::JSONB,
    "isAllowEmpty" boolean
);

ALTER TABLE ALERTS
    OWNER TO POSTGRES;

GRANT SELECT ON ALERTS TO BN_RO;

GRANT SELECT ON ALERTS TO BN_RO_ROLE;

GRANT SELECT ON ALERTS TO BN_RO_USER1;

GRANT SELECT ON ALERTS TO DEJAN_USER;

