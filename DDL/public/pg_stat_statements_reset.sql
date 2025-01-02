CREATE FUNCTION PG_STAT_STATEMENTS_RESET(userid oid default 0, dbid oid default 0, queryid bigint default 0) RETURNS void
    STRICT
    PARALLEL SAFE
    LANGUAGE C
AS
$$
begin
-- missing source code
end;
$$;

ALTER FUNCTION PG_STAT_STATEMENTS_RESET(oid, oid, bigint) OWNER TO RDSADMIN;

GRANT EXECUTE ON FUNCTION PG_STAT_STATEMENTS_RESET(oid, oid, bigint) TO RDS_SUPERUSER;

