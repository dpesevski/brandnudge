CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER proddb_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'brandnudge-db-cluster-prod.cluster-cgtow2b7iejj.eu-north-1.rds.amazonaws.com', port '5432', dbname 'brandnudge');
CREATE USER MAPPING FOR postgres SERVER proddb_fdw OPTIONS (user 'dejan_user', password 'nCIqhxXgwItIGtK');

CREATE SCHEMA prod_fdw;
IMPORT FOREIGN SCHEMA public FROM SERVER proddb_fdw INTO prod_fdw;

