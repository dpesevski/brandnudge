CREATE VIEW PG_STAT_STATEMENTS
            (USERID, DBID, QUERYID, QUERY, CALLS, TOTAL_TIME, MIN_TIME, MAX_TIME, MEAN_TIME, STDDEV_TIME, ROWS,
             SHARED_BLKS_HIT, SHARED_BLKS_READ, SHARED_BLKS_DIRTIED, SHARED_BLKS_WRITTEN, LOCAL_BLKS_HIT,
             LOCAL_BLKS_READ, LOCAL_BLKS_DIRTIED, LOCAL_BLKS_WRITTEN, TEMP_BLKS_READ, TEMP_BLKS_WRITTEN, BLK_READ_TIME,
             BLK_WRITE_TIME)
AS
SELECT pg_stat_statements.userid,
       pg_stat_statements.dbid,
       pg_stat_statements.queryid,
       pg_stat_statements.query,
       pg_stat_statements.calls,
       pg_stat_statements.total_time,
       pg_stat_statements.min_time,
       pg_stat_statements.max_time,
       pg_stat_statements.mean_time,
       pg_stat_statements.stddev_time,
       pg_stat_statements.rows,
       pg_stat_statements.shared_blks_hit,
       pg_stat_statements.shared_blks_read,
       pg_stat_statements.shared_blks_dirtied,
       pg_stat_statements.shared_blks_written,
       pg_stat_statements.local_blks_hit,
       pg_stat_statements.local_blks_read,
       pg_stat_statements.local_blks_dirtied,
       pg_stat_statements.local_blks_written,
       pg_stat_statements.temp_blks_read,
       pg_stat_statements.temp_blks_written,
       pg_stat_statements.blk_read_time,
       pg_stat_statements.blk_write_time
FROM pg_stat_statements(TRUE) pg_stat_statements(userid, dbid, queryid, query, calls, total_time, min_time, max_time,
                                                 mean_time, stddev_time, rows, shared_blks_hit, shared_blks_read,
                                                 shared_blks_dirtied, shared_blks_written, local_blks_hit,
                                                 local_blks_read, local_blks_dirtied, local_blks_written,
                                                 temp_blks_read, temp_blks_written, blk_read_time, blk_write_time);

ALTER TABLE PG_STAT_STATEMENTS
    OWNER TO RDSADMIN;

GRANT SELECT ON PG_STAT_STATEMENTS TO PUBLIC;

GRANT SELECT ON PG_STAT_STATEMENTS TO BN_RO_ROLE;

GRANT SELECT ON PG_STAT_STATEMENTS TO BN_RO_USER1;

GRANT SELECT ON PG_STAT_STATEMENTS TO DEJAN_USER;

CREATE FUNCTION PG_STAT_STATEMENTS(showtext boolean, out userid oid, out dbid oid, out queryid bigint, out query text, out calls bigint, out total_time double precision, out min_time double precision, out max_time double precision, out mean_time double precision, out stddev_time double precision, out rows bigint, out shared_blks_hit bigint, out shared_blks_read bigint, out shared_blks_dirtied bigint, out shared_blks_written bigint, out local_blks_hit bigint, out local_blks_read bigint, out local_blks_dirtied bigint, out local_blks_written bigint, out temp_blks_read bigint, out temp_blks_written bigint, out blk_read_time double precision, out blk_write_time double precision) RETURNS setof setof record
    STRICT
    PARALLEL SAFE
    LANGUAGE C
AS
$$
begin
-- missing source code
end;

$$;

ALTER FUNCTION PG_STAT_STATEMENTS(boolean, OUT oid, OUT oid, OUT bigint, OUT text, OUT bigint, OUT double precision, OUT double precision, OUT double precision, OUT double precision, OUT double precision, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT double precision, OUT double precision) OWNER TO RDSADMIN;

