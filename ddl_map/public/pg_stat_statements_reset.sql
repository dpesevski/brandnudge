CREATE FUNCTION pg_stat_statements_reset(userid oid default 0, dbid oid default 0, queryid bigint default 0) RETURNS void
    STRICT
    PARALLEL SAFE
    LANGUAGE c
AS
$$
begin
-- missing source code
end;
$$;

ALTER FUNCTION pg_stat_statements_reset(oid, oid, bigint) OWNER TO rdsadmin;

GRANT EXECUTE ON FUNCTION pg_stat_statements_reset(oid, oid, bigint) TO rds_superuser;

