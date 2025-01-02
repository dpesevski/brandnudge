CREATE FOREIGN TABLE PROD_FDW.PG_STAT_STATEMENTS
    (
        USERID OID OPTIONS (column_name 'userid'),
        DBID OID OPTIONS (column_name 'dbid'),
        QUERYID bigint OPTIONS (column_name 'queryid'),
        QUERY text OPTIONS (column_name 'query'),
        CALLS bigint OPTIONS (column_name 'calls'),
        TOTAL_TIME double precision OPTIONS (column_name 'total_time'),
        MIN_TIME double precision OPTIONS (column_name 'min_time'),
        MAX_TIME double precision OPTIONS (column_name 'max_time'),
        MEAN_TIME double precision OPTIONS (column_name 'mean_time'),
        STDDEV_TIME double precision OPTIONS (column_name 'stddev_time'),
        ROWS bigint OPTIONS (column_name 'rows'),
        SHARED_BLKS_HIT bigint OPTIONS (column_name 'shared_blks_hit'),
        SHARED_BLKS_READ bigint OPTIONS (column_name 'shared_blks_read'),
        SHARED_BLKS_DIRTIED bigint OPTIONS (column_name 'shared_blks_dirtied'),
        SHARED_BLKS_WRITTEN bigint OPTIONS (column_name 'shared_blks_written'),
        LOCAL_BLKS_HIT bigint OPTIONS (column_name 'local_blks_hit'),
        LOCAL_BLKS_READ bigint OPTIONS (column_name 'local_blks_read'),
        LOCAL_BLKS_DIRTIED bigint OPTIONS (column_name 'local_blks_dirtied'),
        LOCAL_BLKS_WRITTEN bigint OPTIONS (column_name 'local_blks_written'),
        TEMP_BLKS_READ bigint OPTIONS (column_name 'temp_blks_read'),
        TEMP_BLKS_WRITTEN bigint OPTIONS (column_name 'temp_blks_written'),
        BLK_READ_TIME double precision OPTIONS (column_name 'blk_read_time'),
        BLK_WRITE_TIME double precision OPTIONS (column_name 'blk_write_time')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'pg_stat_statements');

ALTER FOREIGN TABLE PROD_FDW.PG_STAT_STATEMENTS
    OWNER TO POSTGRES;

