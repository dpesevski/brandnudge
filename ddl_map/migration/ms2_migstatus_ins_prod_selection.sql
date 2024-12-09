CREATE TABLE migration.ms2_migstatus_ins_prod_selection
(
    id               integer NOT NULL
        CONSTRAINT migstatus_ins_prod_selection_pk
            PRIMARY KEY,
    delisted_date    date,
    delisted_date_id integer
);

ALTER TABLE migration.ms2_migstatus_ins_prod_selection
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_migstatus_ins_prod_selection TO bn_ro;

GRANT SELECT ON migration.ms2_migstatus_ins_prod_selection TO dejan_user;

