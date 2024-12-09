CREATE TABLE notifications
(
    id               serial
        PRIMARY KEY,
    "userId"         integer,
    message          text,
    status           boolean,
    "scraperErrorId" integer,
    "productErrorId" integer,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE notifications
    OWNER TO postgres;

