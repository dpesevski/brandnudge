CREATE TYPE enum_users_status AS enum ('active', 'blocked', 'inactive');

ALTER TYPE enum_users_status OWNER TO postgres;

