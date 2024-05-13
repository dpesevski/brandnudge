CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER devdb_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'brandnudge-db-cluster-test-v2.cluster-cgtow2b7iejj.eu-north-1.rds.amazonaws.com', port '5432', dbname 'brandnudge-dev');
CREATE USER MAPPING FOR postgres SERVER devdb_fdw OPTIONS (user 'postgres', password 'fPQWtdGp2zMe4NNr');

IMPORT FOREIGN SCHEMA staging FROM SERVER devdb_fdw INTO dev_staging;


CREATE TABLE staging.dev_retailer_daily_data AS
SELECT *
FROM dev_staging.retailer_daily_data