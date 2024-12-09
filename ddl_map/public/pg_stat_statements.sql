CREATE VIEW pg_stat_statements
            (userid, dbid, queryid, query, calls, total_time, min_time, max_time, mean_time, stddev_time, rows,
             shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, local_blks_hit,
             local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written, blk_read_time,
             blk_write_time)
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

ALTER TABLE pg_stat_statements
    OWNER TO rdsadmin;

GRANT SELECT ON pg_stat_statements TO PUBLIC;

GRANT SELECT ON pg_stat_statements TO bn_ro_role;

GRANT SELECT ON pg_stat_statements TO bn_ro_user1;

GRANT SELECT ON pg_stat_statements TO dejan_user;

CREATE FUNCTION pg_stat_statements(showtext boolean, out userid oid, out dbid oid, out queryid bigint, out query text, out calls bigint, out total_time double precision, out min_time double precision, out max_time double precision, out mean_time double precision, out stddev_time double precision, out rows bigint, out shared_blks_hit bigint, out shared_blks_read bigint, out shared_blks_dirtied bigint, out shared_blks_written bigint, out local_blks_hit bigint, out local_blks_read bigint, out local_blks_dirtied bigint, out local_blks_written bigint, out temp_blks_read bigint, out temp_blks_written bigint, out blk_read_time double precision, out blk_write_time double precision) RETURNS setof setof record
    STRICT
    PARALLEL SAFE
    LANGUAGE C
AS
$$
begin
-- missing source code
end;

$$;

ALTER FUNCTION pg_stat_statements(boolean, OUT oid, OUT oid, OUT bigint, OUT text, OUT bigint, OUT double precision, OUT double precision, OUT double precision, OUT double precision, OUT double precision, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT bigint, OUT double precision, OUT double precision) OWNER TO rdsadmin;

