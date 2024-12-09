CREATE TABLE alerts
(
    id             serial
        PRIMARY KEY,
    name           varchar(255),
    "userId"       integer
        REFERENCES users,
    schedule       jsonb,
    filters        jsonb,
    pricing        jsonb,
    promotion      jsonb,
    availability   jsonb,
    listing        jsonb,
    sms            boolean,
    "whatsApp"     boolean,
    "createdAt"    timestamp with time zone NOT NULL,
    "updatedAt"    timestamp with time zone NOT NULL,
    message        text  DEFAULT ''::text,
    emails         jsonb DEFAULT '[]'::jsonb,
    "isAllowEmpty" boolean
);

ALTER TABLE alerts
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON alerts_pkey TO postgres;

GRANT SELECT ON alerts_pkey TO bn_ro;

GRANT SELECT ON alerts_pkey TO bn_ro_role;

GRANT SELECT ON alerts_pkey TO bn_ro_user1;

GRANT SELECT ON alerts_pkey TO dejan_user;

GRANT SELECT ON alerts TO bn_ro;

GRANT SELECT ON alerts TO bn_ro_role;

GRANT SELECT ON alerts TO bn_ro_user1;

GRANT SELECT ON alerts TO dejan_user;

