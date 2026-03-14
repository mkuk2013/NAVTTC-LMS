--
-- PostgreSQL database dump
--

\restrict XmtWcI44lXOBtOHvtB4m8VT4HvAbPkOZywS3if8ASVvA2Fk7a3mkt5jlaHfezdP

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  BEGIN
      RAISE DEBUG 'PgBouncer auth request: %', p_usename;

      RETURN QUERY
      SELECT
          rolname::text,
          CASE WHEN rolvaliduntil < now()
              THEN null
              ELSE rolpassword::text
          END
      FROM pg_authid
      WHERE rolname=$1 and rolcanlogin;
  END;
  $_$;


--
-- Name: admin_reset_password(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_reset_password(target_user_id uuid, new_password text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- We assume your app checks if the CURRENT user is an admin before calling this.
  -- Update the auth.users table with the new encrypted password.
  -- Note: Supabase's auth schema handles the actual hashing when using the API, 
  -- but direct SQL requires using the internal built-in crypto functions if updating directly.
  
  -- The safest way to do this in Supabase without external crypto extensions is via the builtin admin API, 
  -- but since RPC is the requested method:
  
  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf'))
  WHERE id = target_user_id;

END;
$$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- We use COALESCE and NEW.raw_user_meta_data to get the name
  -- If 'name' is in options.data, it ends up in raw_user_meta_data
  INSERT INTO public.profiles (id, uid, full_name, email, role, status)
  VALUES (
    NEW.id, 
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email), 
    NEW.email, 
    'student', 
    'pending'
  );
  RETURN NEW;
END;
$$;


--
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  );
END;
$$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_
        -- Filter by action early - only get subscriptions interested in this action
        -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
        and (subs.action_filter = '*' or subs.action_filter = action::text);

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    -- Generate a new UUID for the id
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
_filename text;
BEGIN
	select string_to_array(name, '/') into _parts;
	select _parts[array_length(_parts,1)] into _filename;
	-- @todo return the last part instead of 2
	return reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[1:array_length(_parts,1)-1];
END
$$;


--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::int) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: admin_chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_chat_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY public.admin_chat_messages REPLICA IDENTITY FULL;


--
-- Name: arcade_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arcade_config (
    id integer NOT NULL,
    is_unlocked boolean DEFAULT false,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: arcade_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arcade_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arcade_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arcade_config_id_seq OWNED BY public.arcade_config.id;


--
-- Name: exam_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_results (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    student_id uuid,
    student_name text,
    score integer,
    total_marks integer,
    status text,
    certificate_id text,
    answers_json jsonb,
    questions_json jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: exam_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_settings (
    id integer NOT NULL,
    is_active boolean DEFAULT false,
    exam_title text,
    duration_minutes integer,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: exam_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_settings_id_seq OWNED BY public.exam_settings.id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    student_id uuid,
    content text NOT NULL,
    rating integer,
    is_read boolean DEFAULT false,
    submitted_at timestamp with time zone DEFAULT now(),
    CONSTRAINT feedback_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- Name: game_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_scores (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid,
    game text NOT NULL,
    score integer NOT NULL,
    max_score integer,
    played_at timestamp with time zone DEFAULT now()
);


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submissions (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    task_id uuid,
    student_id uuid,
    content text,
    status text DEFAULT 'pending'::text,
    grade text,
    feedback text,
    submitted_at timestamp with time zone DEFAULT now(),
    student_name text,
    task_title text
);


--
-- Name: leaderboard_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.leaderboard_view AS
 SELECT student_id,
    student_name,
    task_id,
    grade,
    status
   FROM public.submissions
  WHERE (status = 'graded'::text);


--
-- Name: notices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notices (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    title text NOT NULL,
    content text,
    priority text DEFAULT 'normal'::text,
    created_by uuid,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: personal_storage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_storage (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid,
    name text NOT NULL,
    url text NOT NULL,
    size integer,
    type text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    uid uuid,
    full_name text,
    email text,
    role text DEFAULT 'student'::text,
    avatar_url text,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['student'::text, 'teacher'::text, 'admin'::text])))
);


--
-- Name: resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resources (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    title text NOT NULL,
    url text NOT NULL,
    description text,
    uploaded_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    subtitle text
);


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    key character varying NOT NULL,
    value text NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: task_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_comments (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    task_id uuid,
    user_id uuid,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    title text NOT NULL,
    description text,
    deadline timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    hints text
);


--
-- Name: user_achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_achievements (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid,
    badge_key text NOT NULL,
    earned_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_arcade_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_arcade_progress (
    user_id uuid NOT NULL,
    points integer DEFAULT 0,
    level integer DEFAULT 1,
    last_played timestamp with time zone
);


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: messages_2026_03_10; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_03_10 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: messages_2026_03_11; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_03_11 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: messages_2026_03_12; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_03_12 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: messages_2026_03_13; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_03_13 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: messages_2026_03_14; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_03_14 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: messages_2026_03_15; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_03_15 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: messages_2026_03_16; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_03_16 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: messages_2026_03_10; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_03_10 FOR VALUES FROM ('2026-03-10 00:00:00') TO ('2026-03-11 00:00:00');


--
-- Name: messages_2026_03_11; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_03_11 FOR VALUES FROM ('2026-03-11 00:00:00') TO ('2026-03-12 00:00:00');


--
-- Name: messages_2026_03_12; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_03_12 FOR VALUES FROM ('2026-03-12 00:00:00') TO ('2026-03-13 00:00:00');


--
-- Name: messages_2026_03_13; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_03_13 FOR VALUES FROM ('2026-03-13 00:00:00') TO ('2026-03-14 00:00:00');


--
-- Name: messages_2026_03_14; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_03_14 FOR VALUES FROM ('2026-03-14 00:00:00') TO ('2026-03-15 00:00:00');


--
-- Name: messages_2026_03_15; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_03_15 FOR VALUES FROM ('2026-03-15 00:00:00') TO ('2026-03-16 00:00:00');


--
-- Name: messages_2026_03_16; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_03_16 FOR VALUES FROM ('2026-03-16 00:00:00') TO ('2026-03-17 00:00:00');


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: arcade_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arcade_config ALTER COLUMN id SET DEFAULT nextval('public.arcade_config_id_seq'::regclass);


--
-- Name: exam_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_settings ALTER COLUMN id SET DEFAULT nextval('public.exam_settings_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('adfe2a8c-2570-4c32-95b2-f70540048848', 'adfe2a8c-2570-4c32-95b2-f70540048848', '{"sub": "adfe2a8c-2570-4c32-95b2-f70540048848", "name": "Demo Student", "email": "demostudent@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-27 16:08:39.925412+00', '2026-02-27 16:08:39.925477+00', '2026-02-27 16:08:39.925477+00', 'e8e2db70-a656-4087-a3a5-e1ddd317b1ac');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('c6769364-3029-4cb3-8b72-ba24c7c5ee5a', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '{"sub": "c6769364-3029-4cb3-8b72-ba24c7c5ee5a", "name": "Tushal Kumar", "email": "tushalparwani@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 04:40:09.931618+00', '2026-02-28 04:40:09.931667+00', '2026-02-28 04:40:09.931667+00', 'd2568e1a-de3d-49a3-814a-acd45b075935');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('805ab41a-0b79-4e31-b0d2-072a072a443b', '805ab41a-0b79-4e31-b0d2-072a072a443b', '{"sub": "805ab41a-0b79-4e31-b0d2-072a072a443b", "name": "Chandar Kumar ", "email": "chandarkumarmalhi502@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 04:42:51.015006+00', '2026-02-28 04:42:51.015054+00', '2026-02-28 04:42:51.015054+00', '71835211-c7a8-498a-97f3-9cda5bb1403f');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('b23c4b2f-c6a9-470e-bb04-b55f96391760', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', '{"sub": "b23c4b2f-c6a9-470e-bb04-b55f96391760", "name": "Shahnawaz ", "email": "shahnwazsamejo786@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 04:45:35.447382+00', '2026-02-28 04:45:35.447454+00', '2026-02-28 04:45:35.447454+00', '285beac2-db6f-40e5-b390-d38874539edf');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('781be76f-8857-4aed-842f-d2ac4acfaa27', '781be76f-8857-4aed-842f-d2ac4acfaa27', '{"sub": "781be76f-8857-4aed-842f-d2ac4acfaa27", "name": "Dilsher ", "email": "dils40732@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 04:48:47.1582+00', '2026-02-28 04:48:47.15826+00', '2026-02-28 04:48:47.15826+00', '1ef678d2-d30c-44fc-b8c0-9cb6b3147fb4');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('b1c43bc7-dee8-4257-8b15-374c11a9c2ed', 'b1c43bc7-dee8-4257-8b15-374c11a9c2ed', '{"sub": "b1c43bc7-dee8-4257-8b15-374c11a9c2ed", "name": "Om Pirkas", "email": "parkashjai124@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 06:14:39.026833+00', '2026-02-28 06:14:39.026882+00', '2026-02-28 06:14:39.026882+00', '7e40ee26-6955-4eba-97c5-0ca1a73514a2');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('717b9547-5aaa-4947-9a03-5dc6d419f68c', '717b9547-5aaa-4947-9a03-5dc6d419f68c', '{"sub": "717b9547-5aaa-4947-9a03-5dc6d419f68c", "name": "Mehander Singh", "email": "rathoremehandersingh@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 07:32:45.971185+00', '2026-02-28 07:32:45.971235+00', '2026-02-28 07:32:45.971235+00', 'b90caf94-df24-4840-a243-1040e445ed85');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('7ba9b0e1-bcdd-4d44-91e9-8f4043ae415b', '7ba9b0e1-bcdd-4d44-91e9-8f4043ae415b', '{"sub": "7ba9b0e1-bcdd-4d44-91e9-8f4043ae415b", "name": "Dolat Rai ", "email": "dolatrai018@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 12:59:41.656197+00', '2026-02-28 12:59:41.656244+00', '2026-02-28 12:59:41.656244+00', '9b831e0d-bb14-4d8c-819a-7e154e80ff55');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('71d95693-e5e9-4626-85fc-4a90e261b5b1', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '{"sub": "71d95693-e5e9-4626-85fc-4a90e261b5b1", "name": "Lajpat ", "email": "lajpatraibheel545@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 14:29:43.39166+00', '2026-02-28 14:29:43.391707+00', '2026-02-28 14:29:43.391707+00', 'c18e1da7-46eb-4798-ba25-add6d045ded6');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('66dc3746-cc17-4afc-b67b-17a4eda74e12', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '{"sub": "66dc3746-cc17-4afc-b67b-17a4eda74e12", "name": "Abdulsalam kunbher ", "email": "salamrahikunbher@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 14:46:36.141249+00', '2026-02-28 14:46:36.141297+00', '2026-02-28 14:46:36.141297+00', 'e99ee141-b61e-4876-92aa-0195b5745d14');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('26143df4-85ca-4a53-a7d9-ea6560e29bf6', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '{"sub": "26143df4-85ca-4a53-a7d9-ea6560e29bf6", "name": "Muhammad Siddique Rahimon ", "email": "muhammadsiddiquerahimoon711@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 14:50:37.49776+00', '2026-02-28 14:50:37.497807+00', '2026-02-28 14:50:37.497807+00', '4e063882-c445-4a0f-b919-1889bbecd516');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('97af47f1-a0f4-423a-8f22-9a8d8a48588f', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', '{"sub": "97af47f1-a0f4-423a-8f22-9a8d8a48588f", "name": "Saroop chand ", "email": "saroopalam@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 15:11:31.9741+00', '2026-02-28 15:11:31.974609+00', '2026-02-28 15:11:31.974609+00', '8c274f25-4075-4ff5-a833-1e2b8bcf3c33');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('08c23b1e-112e-4291-9c0b-551f16632f05', '08c23b1e-112e-4291-9c0b-551f16632f05', '{"sub": "08c23b1e-112e-4291-9c0b-551f16632f05", "name": "Hidayatallah ", "email": "hidayatallahsamejo2@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 15:31:51.628954+00', '2026-02-28 15:31:51.629009+00', '2026-02-28 15:31:51.629009+00', 'b05115b3-a22c-4d05-8b7e-5ab54c1c1646');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '{"sub": "05dafca0-fdd7-4acc-bba5-ec4ee9aca6be", "name": "Muhammad Khan Nohari", "email": "muhammadkhannohari720@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-02-28 15:37:26.431577+00', '2026-02-28 15:37:26.432013+00', '2026-02-28 15:37:26.432013+00', '8bdb1ba2-a55a-4155-b370-da11100e7823');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('7d38a189-b1d5-401e-aba2-36824936da29', '7d38a189-b1d5-401e-aba2-36824936da29', '{"sub": "7d38a189-b1d5-401e-aba2-36824936da29", "name": "MuneerRaza Samejo", "email": "samejomuneerraza@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-01 04:12:45.02144+00', '2026-03-01 04:12:45.021493+00', '2026-03-01 04:12:45.021493+00', 'baf2f110-88ae-4260-a16b-1ed55c42f497');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('e5540156-8936-4a5c-ab78-4f1b503649f0', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '{"sub": "e5540156-8936-4a5c-ab78-4f1b503649f0", "name": "Ompirkash Bheel", "email": "ompirkashbheel417@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-01 04:34:32.25823+00', '2026-03-01 04:34:32.258282+00', '2026-03-01 04:34:32.258282+00', '0328d460-094d-4681-98f3-235684d4c723');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('94b1710e-1c51-4f1b-87a0-fceaffaebd73', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '{"sub": "94b1710e-1c51-4f1b-87a0-fceaffaebd73", "name": "Narender Kumar ", "email": "malangnk67@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-01 09:08:05.919919+00', '2026-03-01 09:08:05.91998+00', '2026-03-01 09:08:05.91998+00', 'd1931d14-1998-42d3-a619-fa426de0b20e');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', '{"sub": "bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6", "name": "Papu", "email": "papuradhani342@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-02 09:51:49.809141+00', '2026-03-02 09:51:49.809655+00', '2026-03-02 09:51:49.809655+00', 'fd7c03ec-91e1-4fd5-a51b-381b27815b7e');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('5c2531cd-11ef-40f9-9789-10bc77e16808', '5c2531cd-11ef-40f9-9789-10bc77e16808', '{"sub": "5c2531cd-11ef-40f9-9789-10bc77e16808", "name": "Rizwan Ali", "email": "alikkrizwan01@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-02 12:15:06.440416+00', '2026-03-02 12:15:06.44048+00', '2026-03-02 12:15:06.44048+00', '410938e7-edd0-4a45-aa4d-746d3b8029ab');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('c551abc6-369e-4722-8a1f-f442501db0a2', 'c551abc6-369e-4722-8a1f-f442501db0a2', '{"sub": "c551abc6-369e-4722-8a1f-f442501db0a2", "name": "Moti Ram", "email": "469mrmb@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-04 09:28:45.846862+00', '2026-03-04 09:28:45.846913+00', '2026-03-04 09:28:45.846913+00', '3bbe9d59-5fa4-49eb-9517-f7015a78a960');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('79ea6f3c-4bff-404b-9539-8b64a36a919b', '79ea6f3c-4bff-404b-9539-8b64a36a919b', '{"sub": "79ea6f3c-4bff-404b-9539-8b64a36a919b", "name": "Usama ", "email": "ranausama000009@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-04 09:40:56.21501+00', '2026-03-04 09:40:56.215461+00', '2026-03-04 09:40:56.215461+00', '4512feaf-07a2-48b6-9366-c9ed2c739e53');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('5c5a6e76-6682-4405-bad4-32817d63619e', '5c5a6e76-6682-4405-bad4-32817d63619e', '{"sub": "5c5a6e76-6682-4405-bad4-32817d63619e", "name": "Rehman ali", "email": "rehmanali2k22@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-04 09:45:47.150694+00', '2026-03-04 09:45:47.151162+00', '2026-03-04 09:45:47.151162+00', '2ba16a0c-d505-42e0-9f59-77daa4651f65');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('4cb50b66-b09c-4b38-8091-4965a170c788', '4cb50b66-b09c-4b38-8091-4965a170c788', '{"sub": "4cb50b66-b09c-4b38-8091-4965a170c788", "name": "Ali Hassan Bajeer", "email": "alihassanbajeer555@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-05 10:14:56.570005+00', '2026-03-05 10:14:56.570056+00', '2026-03-05 10:14:56.570056+00', 'f21afa65-6845-4a6b-8065-3c61d4dcff5d');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('494e18ab-b18b-4f7d-b33a-83ac7d3d480f', '494e18ab-b18b-4f7d-b33a-83ac7d3d480f', '{"sub": "494e18ab-b18b-4f7d-b33a-83ac7d3d480f", "name": "Munawar hussain", "email": "vehroroadsammamohlla@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-06 08:27:22.974081+00', '2026-03-06 08:27:22.974133+00', '2026-03-06 08:27:22.974133+00', '3ab5930d-7b39-45a6-9519-5a9bcaa4298c');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('08a46873-b1cf-4b3e-92b2-37e662a11775', '08a46873-b1cf-4b3e-92b2-37e662a11775', '{"sub": "08a46873-b1cf-4b3e-92b2-37e662a11775", "name": "Hidayatullah", "email": "hidayat.wali3600@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-06 15:16:12.71192+00', '2026-03-06 15:16:12.711966+00', '2026-03-06 15:16:12.711966+00', 'a16ca513-53a8-453b-9bbb-4864ff5c84a6');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('025e3598-2401-4955-91c8-e8d9c32542fb', '025e3598-2401-4955-91c8-e8d9c32542fb', '{"sub": "025e3598-2401-4955-91c8-e8d9c32542fb", "name": "Mukesh Kumar", "email": "mkuk2015@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-07 17:27:23.119967+00', '2026-03-07 17:27:23.120321+00', '2026-03-07 17:27:23.120321+00', '02dc5ab7-f7df-4837-93f3-6b5e87d363e5');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('38dfd37b-123f-4938-93b3-dca1dfbb4b08', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', '{"sub": "38dfd37b-123f-4938-93b3-dca1dfbb4b08", "name": "Anand kumar", "email": "anandkumarmalhi440@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-08 11:50:05.447821+00', '2026-03-08 11:50:05.447873+00', '2026-03-08 11:50:05.447873+00', '5945ab7d-2585-4707-8894-d9ae42642331');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', '{"sub": "9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac", "name": "Partab ", "email": "kumarpartab109@gmail.com", "email_verified": false, "phone_verified": false}', 'email', '2026-03-10 02:34:29.192833+00', '2026-03-10 02:34:29.192889+00', '2026-03-10 02:34:29.192889+00', '6c876ec1-11a2-4fd0-8a12-875f7d0598d6');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('ca867a31-f1d8-4d35-872d-81a72184fca1', '2026-03-02 15:59:52.438972+00', '2026-03-02 15:59:52.438972+00', 'password', 'd576670c-ac3e-4fd9-ac7f-b27275e056d1');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('9d04eada-0910-44d4-bcfa-ab1e7799809c', '2026-03-02 16:00:46.509734+00', '2026-03-02 16:00:46.509734+00', 'password', '11826ec0-2fd8-4373-b01d-8ef199fdf1a9');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('ef9e7c65-c427-4f40-bca3-e5581e121a83', '2026-03-02 16:01:10.511677+00', '2026-03-02 16:01:10.511677+00', 'password', 'c863afc4-7313-46a6-be41-3b42a14502a6');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('b743773b-a449-41af-aebf-b4c16854dce1', '2026-03-02 16:01:17.8754+00', '2026-03-02 16:01:17.8754+00', 'password', '7f0b9793-dd93-41aa-bd55-5bbbbd60a89f');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('246c555e-ed53-4e87-be1b-26a62c77df86', '2026-03-02 16:01:20.656939+00', '2026-03-02 16:01:20.656939+00', 'password', 'adffba8c-6427-460f-b4b4-6d9444223212');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('2d57e562-1e47-4f19-b795-8c24cf5ef2d8', '2026-03-02 16:01:21.750963+00', '2026-03-02 16:01:21.750963+00', 'password', '7a934e5e-3dea-4511-9362-c322e09e25f5');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('3fada469-fba8-4ee9-90fd-dccec49b469f', '2026-03-02 16:01:29.379843+00', '2026-03-02 16:01:29.379843+00', 'password', '9a0e401c-5d51-4c8a-87db-16015d23edad');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('cbf7820d-ea74-4aca-8710-f1988ebc6473', '2026-03-02 16:01:31.791975+00', '2026-03-02 16:01:31.791975+00', 'password', 'ec81dea0-74fa-4512-837c-d6baff571a49');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('cd274e3e-06ad-4fe3-91a2-5b15f683a044', '2026-03-02 16:01:40.442045+00', '2026-03-02 16:01:40.442045+00', 'password', 'bdd08919-ba37-4221-b7b9-647eb5fe6ada');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('d479f696-a92e-499f-98ee-3265222309ef', '2026-03-02 16:01:49.191752+00', '2026-03-02 16:01:49.191752+00', 'password', 'd9e266f5-7a1c-422a-a089-de5f4d96532e');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('a5580446-6c88-44fc-9a32-410af5f8a9e5', '2026-03-02 16:01:52.012897+00', '2026-03-02 16:01:52.012897+00', 'password', '99df7c4e-d1dd-4d35-99c3-eccf90d23bf7');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('b763e30d-92ea-4cce-b2d5-f07142e02ed2', '2026-03-02 16:01:55.762328+00', '2026-03-02 16:01:55.762328+00', 'password', '4ad111da-ff26-4c59-b7ef-69c967971715');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('f773e0de-2a9d-452f-933f-d99dded37e2a', '2026-03-02 16:01:58.234305+00', '2026-03-02 16:01:58.234305+00', 'password', '530b0c64-9acd-4c4b-938e-666d2389e8e9');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('9dc59fe3-bf49-4d64-bfaa-14ce43475141', '2026-03-02 16:02:09.578309+00', '2026-03-02 16:02:09.578309+00', 'password', 'ad18ea33-5c49-4ef3-bc9f-00f1322aec11');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('86378985-942c-4d1c-a858-d2adc5a3173f', '2026-02-28 15:30:32.876731+00', '2026-02-28 15:30:32.876731+00', 'password', '66864e86-4452-4089-b841-e6abc2303f7f');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('79eb8d49-de78-43e4-a269-2e73bd9ba965', '2026-03-02 16:02:14.934584+00', '2026-03-02 16:02:14.934584+00', 'password', 'f3299f46-4092-44fb-a38c-1819d7f74814');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('27cbf38c-9108-4eb4-a081-16d6f7982021', '2026-02-28 15:32:01.832342+00', '2026-02-28 15:32:01.832342+00', 'password', '5b4e2106-a65e-4834-9497-a9e86070fb40');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('a7af0387-ff7b-4722-a62f-9153fbd6ec99', '2026-03-02 16:02:14.946605+00', '2026-03-02 16:02:14.946605+00', 'password', '8d5e9004-5dd3-42bd-8b0d-ee642ccaaac7');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('03fba9ba-31f8-4cb2-89b7-c496b0e79935', '2026-03-02 16:02:17.439258+00', '2026-03-02 16:02:17.439258+00', 'password', '9cd3943b-7d33-4fe3-8fcf-ea234814a68d');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('fe7d0f79-3be6-4799-9bd8-3f7ebfa94246', '2026-02-28 15:38:23.603715+00', '2026-02-28 15:38:23.603715+00', 'password', '7eb67127-4316-47b5-a993-f9a3b16c2899');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('128926ba-9fd5-4024-9884-0bb319152425', '2026-03-12 13:01:03.933027+00', '2026-03-12 13:01:03.933027+00', 'password', '9403f435-87d2-47f7-9635-ce9c3fa69930');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('a3b7762f-88ce-4087-aa59-8a7b0b89d0f2', '2026-03-13 15:52:15.560726+00', '2026-03-13 15:52:15.560726+00', 'password', '57fe1769-89c3-4779-ae28-da1825334af4');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('7415b761-99f8-4684-8e3e-6f007f370946', '2026-03-13 17:47:58.010696+00', '2026-03-13 17:47:58.010696+00', 'password', 'd3df122b-3e4f-459b-bb40-12a36b70ff4c');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('acaa1c68-5539-4f14-b89e-7c6dc6aa0bf1', '2026-03-06 09:24:34.739858+00', '2026-03-06 09:24:34.739858+00', 'password', '8c791a09-77b4-4b20-897e-6a5929d0096a');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('fd621fa3-5b30-4fe6-bc46-620173a269b2', '2026-03-03 06:03:48.069659+00', '2026-03-03 06:03:48.069659+00', 'password', 'bb79829a-7613-49f6-84a7-21d9d6bfffbd');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('fe70f434-367b-4e36-a64c-fe24b0b8e717', '2026-03-03 06:15:36.036359+00', '2026-03-03 06:15:36.036359+00', 'password', '4d8cb980-5a18-403e-8751-b1434ef1dca7');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('ff2cd62f-f762-403d-b73d-048f6af1fdb8', '2026-03-06 09:28:59.587917+00', '2026-03-06 09:28:59.587917+00', 'password', 'c812d8fb-a574-476a-b5f7-0e4311b6d187');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('10524fe0-e505-4146-b96f-62adfd42ba19', '2026-02-28 23:37:18.655536+00', '2026-02-28 23:37:18.655536+00', 'password', '6c96dcf4-d7d2-4a8e-9420-9b5694359eb5');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641', '2026-03-10 15:40:34.990187+00', '2026-03-10 15:40:34.990187+00', 'password', '9ed46eaa-7c5f-4953-b410-2250175632ad');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('8de9e949-9b8c-4bf0-8085-a16d19877804', '2026-03-06 09:38:55.537036+00', '2026-03-06 09:38:55.537036+00', 'password', '23e421c4-3167-4f79-9536-76f2c2cf3de4');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('0e2bcd34-2a6a-4917-af86-4ab5970d2fd2', '2026-03-01 04:25:28.060574+00', '2026-03-01 04:25:28.060574+00', 'password', 'ba2392b3-b39e-4ff1-a347-514e7fd09005');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('7b5e59c3-47a7-4e09-8723-01005e95ece4', '2026-03-01 12:34:17.734578+00', '2026-03-01 12:34:17.734578+00', 'password', 'd7ba1a19-ac7e-4921-840f-d30b80336969');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('ca021e11-f82d-46df-b68d-6d7ec803b7e7', '2026-03-11 09:39:18.495396+00', '2026-03-11 09:39:18.495396+00', 'password', '33cc2df9-c939-4b8f-9269-b1de3ebe6199');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('348223b8-a885-4548-b609-0811ce2224bd', '2026-03-11 10:13:42.224473+00', '2026-03-11 10:13:42.224473+00', 'password', '12067ddc-8966-473c-a480-6cfe62d90685');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('8ab9f851-b08b-4efb-bc95-5250aff059f3', '2026-03-11 10:14:20.773806+00', '2026-03-11 10:14:20.773806+00', 'otp', '7eee4d85-3319-494f-91e8-c58f8fcb0b6c');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('51edfdb8-a720-4ace-b01e-745773828af6', '2026-03-11 10:15:10.178116+00', '2026-03-11 10:15:10.178116+00', 'password', '68fbbad1-3ba5-4065-ae0a-e63f97e07a1e');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('666ddd72-dc90-4603-a516-6ee6f09a558f', '2026-03-06 16:28:47.868174+00', '2026-03-06 16:28:47.868174+00', 'password', 'f7cccfc5-f672-4fae-a530-8b5d2802848c');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('812df86d-8f84-4c27-b728-a148075555ca', '2026-03-02 10:15:29.227785+00', '2026-03-02 10:15:29.227785+00', 'password', 'ba6d7f93-bfaa-4186-842b-292cc1e9ee38');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('3fca260f-e54d-4c9f-9a6f-0ba32894f5ea', '2026-03-11 16:28:04.355164+00', '2026-03-11 16:28:04.355164+00', 'password', '55dad69b-4810-4233-8970-aa93e15c40a4');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('a9cb4a50-76dd-4ffa-9598-272834953588', '2026-03-07 02:50:53.818839+00', '2026-03-07 02:50:53.818839+00', 'password', 'd9331938-382b-4d90-868b-a6bab38e6e9f');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('92e5d6e1-9b1a-4e22-bc23-38878a1957c8', '2026-03-04 09:41:43.592605+00', '2026-03-04 09:41:43.592605+00', 'password', 'af6b86f1-6708-466c-967c-639907f784ce');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('f403d187-b910-495a-a3a6-46678bd444dd', '2026-03-12 02:12:51.523724+00', '2026-03-12 02:12:51.523724+00', 'password', 'c47a5606-d678-4cf3-a482-086aee7c5714');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('5fe595b7-b160-4372-8c31-87e667096395', '2026-03-04 10:03:03.427645+00', '2026-03-04 10:03:03.427645+00', 'password', 'bbc6a979-f8b3-462d-b62e-d15395521057');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('90dc03e3-ae2a-496c-b468-2c033578e6e8', '2026-03-04 10:10:11.898834+00', '2026-03-04 10:10:11.898834+00', 'password', '77d29ef6-82a3-40e9-91f1-3f83947e1beb');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('a20bb4ea-e677-4a3f-bd10-4fd3f57a4648', '2026-03-12 02:53:58.479627+00', '2026-03-12 02:53:58.479627+00', 'password', '81419419-0dd9-47c2-ae5f-c7d63b25bf29');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('4faa9291-e18c-4de9-905c-2808c78bb264', '2026-03-07 12:36:18.718752+00', '2026-03-07 12:36:18.718752+00', 'password', '1d7be725-e9ac-4987-8177-09729fb82807');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('75f843a2-1284-4801-bb5f-7f275d4dd457', '2026-03-12 09:34:30.097609+00', '2026-03-12 09:34:30.097609+00', 'password', '48f887da-d3db-4349-8fd9-fca4922533f4');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('597bf3e7-3932-4548-a4c7-f11fdaee2a0c', '2026-03-12 09:47:00.078268+00', '2026-03-12 09:47:00.078268+00', 'password', '4fbe3e9e-2cac-49be-b763-d532fc2210c2');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('3d9df9a2-2d8c-4a10-bd4f-c198a8a40b2d', '2026-03-12 09:53:03.766731+00', '2026-03-12 09:53:03.766731+00', 'password', '707c91d2-fa1a-414a-bd98-9829fa57ad47');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('af4c298a-288a-460a-b53a-f2d46008f86a', '2026-03-07 17:26:31.213961+00', '2026-03-07 17:26:31.213961+00', 'password', '515c9fba-4305-4aec-b19d-5943a59c3e27');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('6fb0429d-40a1-48cc-a107-a5c218ee99b5', '2026-03-05 04:18:26.687336+00', '2026-03-05 04:18:26.687336+00', 'password', '2afb2ba2-cfc9-476c-ae94-4facefaaf9ac');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('2df65f47-ebf2-489f-8ccc-a482e6972efe', '2026-03-05 05:43:46.84878+00', '2026-03-05 05:43:46.84878+00', 'password', 'a7971aac-51c7-4d11-a028-01f5956ce901');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('d55783f9-a875-454b-97cd-e3957b966821', '2026-03-07 18:01:41.997092+00', '2026-03-07 18:01:41.997092+00', 'password', '0368118d-d645-4cb9-b8bc-d8d9ddb0007e');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('d916e10d-7753-483e-9136-ed122851652f', '2026-03-05 09:22:59.15941+00', '2026-03-05 09:22:59.15941+00', 'password', '6b8153c5-5add-4d1a-8de2-0a9a7615a618');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('6d37d23d-7706-47d7-a509-5586f95160b8', '2026-03-05 10:03:24.662246+00', '2026-03-05 10:03:24.662246+00', 'password', 'a9056e79-6932-4e85-9d3e-06cd10047cd4');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('d49eb474-ca18-4fd7-a1d8-db8ce73c69c4', '2026-03-05 10:16:28.202564+00', '2026-03-05 10:16:28.202564+00', 'password', '2b1d2ba7-3342-463a-9093-2bb800ed78d8');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('664cb064-da97-420d-938a-b010e0b84c64', '2026-03-05 12:50:20.56775+00', '2026-03-05 12:50:20.56775+00', 'password', '8cbcb6f9-3824-4e74-82cc-f91f325b29c4');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('601f8149-3d6f-47b5-b21a-f63706c51de1', '2026-03-08 06:40:49.45059+00', '2026-03-08 06:40:49.45059+00', 'password', '943ca3ed-a34d-44ab-b8de-64a46d52d25c');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('32a73cb8-db9d-440d-be68-464ffc13c02a', '2026-03-08 07:33:53.763383+00', '2026-03-08 07:33:53.763383+00', 'password', '678f982e-aea3-4aae-99e3-3f7474119f6a');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('d96f5a0c-5e88-4e0e-a4b7-884191afe5ed', '2026-03-08 10:12:42.047962+00', '2026-03-08 10:12:42.047962+00', 'password', 'c5ecd490-371b-4e70-b7bd-80fee5b5a77b');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('8e45b52c-3ca9-449c-a6bd-00d5dfaaf1c4', '2026-03-08 14:32:39.620674+00', '2026-03-08 14:32:39.620674+00', 'password', '7c835c25-0053-45fd-9199-5fea6ad5e1c6');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('98378a67-f2e0-4698-9fc6-ed86603c3d2a', '2026-03-10 07:56:34.368828+00', '2026-03-10 07:56:34.368828+00', 'password', 'c01420f6-064c-4230-acae-f12103e90fe3');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('bc45de2a-3585-4efc-af2a-eee4b4ca183f', '2026-03-12 13:56:35.104376+00', '2026-03-12 13:56:35.104376+00', 'password', 'a3c74517-d9fc-48a2-847a-d4422a5dcfec');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('0a63e534-77c5-4a42-969d-ddf21f06eee2', '2026-03-10 09:55:22.368229+00', '2026-03-10 09:55:22.368229+00', 'password', '2c92383d-621a-4aee-951d-fa46092217b3');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('82a6d680-b9a7-4b13-a5b0-2ca6095c3cfb', '2026-03-13 17:00:02.929621+00', '2026-03-13 17:00:02.929621+00', 'password', 'a04e1ac5-a5b1-418e-8c97-3f44884c0c9d');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('eff59d0d-1e66-43ad-aa43-7a3639b7a649', '2026-03-11 08:15:55.792546+00', '2026-03-11 08:15:55.792546+00', 'password', '7767e512-8323-4c5f-b581-56925375e1eb');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b', '2026-03-11 09:39:11.189588+00', '2026-03-11 09:39:11.189588+00', 'password', '7002ad5c-1e69-4dea-9332-40b31d291ce3');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('d3bef874-b76a-46f9-9524-a3539551e1f8', '2026-03-11 10:36:13.749461+00', '2026-03-11 10:36:13.749461+00', 'password', '8d1ae324-4fd7-47b8-ab32-e9d2d5e496bc');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('0004f6b4-6d70-408c-9371-6744d219688d', '2026-03-11 21:17:21.36857+00', '2026-03-11 21:17:21.36857+00', 'password', '1c3fc946-e886-4223-9d15-a1beb009f5b8');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('e07d8672-d6c7-4f89-b493-d69af60bb784', '2026-03-12 02:18:14.854266+00', '2026-03-12 02:18:14.854266+00', 'password', 'de5fffbb-c85e-423f-9d5d-512dcc8a4b52');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('6c491caf-bbdc-46ec-976d-82e593918525', '2026-03-12 03:58:33.321529+00', '2026-03-12 03:58:33.321529+00', 'password', '457d353e-c56a-4aa1-9b7c-ae28bfa53a5c');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('dd68870e-5987-4151-97ad-64ae16665c01', '2026-03-12 09:39:48.230476+00', '2026-03-12 09:39:48.230476+00', 'password', '5171cba5-eced-4bb1-b52d-2ac40da8b938');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('9522ca1b-364f-46e3-9a4d-14ef03e2ad1f', '2026-03-12 09:48:05.244359+00', '2026-03-12 09:48:05.244359+00', 'password', '8da8ab4e-73e8-4c80-a296-9180b3ea6ca7');


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) VALUES ('6b4ba181-57fb-48dd-a8f5-12e2e7a1d3b0', '08a46873-b1cf-4b3e-92b2-37e662a11775', 'recovery_token', 'ea633a19de8cf2fa51ee460fe169f5392171db187bbabd6855639f12', 'hidayat.wali3600@gmail.com', '2026-03-06 15:30:12.698843', '2026-03-06 15:30:12.698843');
INSERT INTO auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) VALUES ('046801d7-917d-45d1-853a-d31abed4aeb8', 'c551abc6-369e-4722-8a1f-f442501db0a2', 'recovery_token', 'a740ec3a1c64948936ef69ecdb4ece51a623c6fe5eef067a39564275', '469mrmb@gmail.com', '2026-03-11 06:52:26.310647', '2026-03-11 06:52:26.310647');
INSERT INTO auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) VALUES ('226683a9-6b6c-411e-9a70-7de94c619f0b', 'e5540156-8936-4a5c-ab78-4f1b503649f0', 'recovery_token', '0b865c6b64f2f95edbb40a69feb22069f81addc7b0873510b5785e8e', 'ompirkashbheel417@gmail.com', '2026-03-11 09:04:19.510038', '2026-03-11 09:04:19.510038');


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 908, 'aemagp6cgqs6', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', false, '2026-03-12 08:08:15.260227+00', '2026-03-12 08:08:15.260227+00', 'io5z5phb3ctc', '8e45b52c-3ca9-449c-a6bd-00d5dfaaf1c4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 268, '3lorlcxgoksc', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-04 06:33:04.405723+00', '2026-03-04 17:53:38.197466+00', 'wuajk3f7l6wg', '86378985-942c-4d1c-a858-d2adc5a3173f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 270, 'mkxhb2z23ivc', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-04 09:09:15.772127+00', '2026-03-05 04:06:27.989332+00', 'mzh5svtprrld', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 811, '2d7zdwuk3kid', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:11.170516+00', '2026-03-11 09:39:11.58146+00', NULL, 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 288, 'v6xnkf77xnin', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-04 10:10:11.861253+00', '2026-03-05 05:43:46.779382+00', NULL, '90dc03e3-ae2a-496c-b468-2c033578e6e8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 916, 'jzsvhmitbvnw', '805ab41a-0b79-4e31-b0d2-072a072a443b', false, '2026-03-12 09:39:48.201811+00', '2026-03-12 09:39:48.201811+00', NULL, 'dd68870e-5987-4151-97ad-64ae16665c01');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 127, 'u2mkdldbejnw', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-02-28 15:32:01.827649+00', '2026-03-01 14:26:46.084279+00', NULL, '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 812, '4fb65iqcllg5', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:11.583948+00', '2026-03-11 09:39:13.067997+00', '2d7zdwuk3kid', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 917, 'qviargbbfyhw', '5c2531cd-11ef-40f9-9789-10bc77e16808', false, '2026-03-12 09:40:18.806011+00', '2026-03-12 09:40:18.806011+00', 'r7iyoy4n5bau', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 299, 'iw2gtr3ggnvg', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-04 16:46:47.966106+00', '2026-03-05 15:23:37.461844+00', 'zkwk6iembpy4', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 813, 'fsj2agjkjo6v', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:13.071111+00', '2026-03-11 09:39:13.693557+00', '4fb65iqcllg5', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 442, 'kh6qm7g3tuws', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-07 09:39:06.664939+00', '2026-03-07 16:21:12.27619+00', '4gqpmrfip5qn', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 980, 'qygpdupbuo3k', '4cb50b66-b09c-4b38-8091-4965a170c788', false, '2026-03-12 09:53:03.666908+00', '2026-03-12 09:53:03.666908+00', NULL, '3d9df9a2-2d8c-4a10-bd4f-c198a8a40b2d');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 452, '66akp3a2dde3', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-07 15:15:57.701139+00', '2026-03-07 18:15:02.449475+00', 'zn6zo4owk7c5', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 814, 'o5knxmm5axay', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:13.694499+00', '2026-03-11 09:39:13.904614+00', 'fsj2agjkjo6v', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 983, '2hckxk3or3fw', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', false, '2026-03-12 11:59:26.984471+00', '2026-03-12 11:59:26.984471+00', 'kcznea3v53ll', '51edfdb8-a720-4ace-b01e-745773828af6');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 165, 'lau5xnmem7j2', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-01 12:34:17.706741+00', '2026-03-03 17:42:53.15383+00', NULL, '7b5e59c3-47a7-4e09-8723-01005e95ece4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 151, 'ddma3j2bawtf', '7d38a189-b1d5-401e-aba2-36824936da29', true, '2026-03-01 04:25:28.053717+00', '2026-03-06 10:24:26.754882+00', NULL, '0e2bcd34-2a6a-4917-af86-4ab5970d2fd2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 815, 'imdderzck2jx', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:13.905128+00', '2026-03-11 09:39:14.253359+00', 'o5knxmm5axay', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 370, 'deuxedjsauc2', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-06 06:49:46.473439+00', '2026-03-07 06:54:30.564492+00', 'zyopo5nhzg2o', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 816, '67r23dn7cesz', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:14.253975+00', '2026-03-11 09:39:15.894368+00', 'imdderzck2jx', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 817, 'hraqywhswvpz', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:15.908802+00', '2026-03-11 09:39:16.459646+00', '67r23dn7cesz', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 818, 'mjt5oamk7ojq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:16.459988+00', '2026-03-11 09:39:17.235377+00', 'hraqywhswvpz', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 819, 'g5bdqu56epx4', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:17.235738+00', '2026-03-11 09:39:18.103854+00', 'mjt5oamk7ojq', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 821, 'r52e7hb5gl5t', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:18.108933+00', '2026-03-11 09:39:19.907663+00', 'g5bdqu56epx4', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 245, 'mzh5svtprrld', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-03 17:22:08.69924+00', '2026-03-04 09:09:15.751475+00', 'mxgehzg4w45t', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 130, 'dnwem7dh2ymj', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-02-28 15:38:23.593609+00', '2026-03-02 13:16:13.368035+00', NULL, 'fe7d0f79-3be6-4799-9bd8-3f7ebfa94246');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 231, 'vk4ef67rwizl', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-03 06:03:48.040753+00', '2026-03-04 09:42:35.916684+00', NULL, 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 142, '44re25ib6jlq', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-02-28 23:37:18.629268+00', '2026-03-02 14:40:47.668781+00', NULL, '10524fe0-e505-4146-b96f-62adfd42ba19');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 248, 'pe7vc7j5ah5k', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-03 17:42:53.201573+00', '2026-03-04 10:01:59.286564+00', 'lau5xnmem7j2', '7b5e59c3-47a7-4e09-8723-01005e95ece4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 178, 'pw62wdlwbcvj', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', true, '2026-03-02 10:15:29.191936+00', '2026-03-04 10:02:35.253893+00', NULL, '812df86d-8f84-4c27-b728-a148075555ca');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 192, 'gvalvewmlxqy', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-02 14:40:47.684852+00', '2026-03-02 15:59:52.377675+00', '44re25ib6jlq', '10524fe0-e505-4146-b96f-62adfd42ba19');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 198, '7ns4blf7pmf2', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 15:59:52.395478+00', '2026-03-02 15:59:52.395478+00', 'gvalvewmlxqy', '10524fe0-e505-4146-b96f-62adfd42ba19');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 199, 'kogdoqfxzftw', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 15:59:52.436775+00', '2026-03-02 15:59:52.436775+00', NULL, 'ca867a31-f1d8-4d35-872d-81a72184fca1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 200, '7lqmwr4v5dnn', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:00:46.497499+00', '2026-03-02 16:00:46.497499+00', NULL, '9d04eada-0910-44d4-bcfa-ab1e7799809c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 187, 'ppll6zrsq5cn', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-02 13:16:13.400836+00', '2026-03-02 16:00:57.059023+00', 'dnwem7dh2ymj', 'fe7d0f79-3be6-4799-9bd8-3f7ebfa94246');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 202, '5mave2nmeqx3', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:10.509525+00', '2026-03-02 16:01:10.509525+00', NULL, 'ef9e7c65-c427-4f40-bca3-e5581e121a83');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 203, 'ffmxls6q4y42', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:17.871644+00', '2026-03-02 16:01:17.871644+00', NULL, 'b743773b-a449-41af-aebf-b4c16854dce1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 204, '2y3sic6vavid', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:20.654412+00', '2026-03-02 16:01:20.654412+00', NULL, '246c555e-ed53-4e87-be1b-26a62c77df86');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 205, 'xznqgxvn46sc', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:21.746754+00', '2026-03-02 16:01:21.746754+00', NULL, '2d57e562-1e47-4f19-b795-8c24cf5ef2d8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 206, 'xvmjuaeh277c', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:29.378144+00', '2026-03-02 16:01:29.378144+00', NULL, '3fada469-fba8-4ee9-90fd-dccec49b469f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 207, 'lkgh3vz2zvnq', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:31.790836+00', '2026-03-02 16:01:31.790836+00', NULL, 'cbf7820d-ea74-4aca-8710-f1988ebc6473');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 208, 'y5kzaiapetvw', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:40.440772+00', '2026-03-02 16:01:40.440772+00', NULL, 'cd274e3e-06ad-4fe3-91a2-5b15f683a044');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 209, '4ah5opfdh3qx', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:49.190586+00', '2026-03-02 16:01:49.190586+00', NULL, 'd479f696-a92e-499f-98ee-3265222309ef');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 210, 'bqxeinzbrdjq', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:52.011672+00', '2026-03-02 16:01:52.011672+00', NULL, 'a5580446-6c88-44fc-9a32-410af5f8a9e5');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 211, 'whaxua2pbkeb', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:55.760637+00', '2026-03-02 16:01:55.760637+00', NULL, 'b763e30d-92ea-4cce-b2d5-f07142e02ed2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 212, '7sst4fowtdlu', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:01:58.233166+00', '2026-03-02 16:01:58.233166+00', NULL, 'f773e0de-2a9d-452f-933f-d99dded37e2a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 213, '4pwfl6x6c72u', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:02:09.573545+00', '2026-03-02 16:02:09.573545+00', NULL, '9dc59fe3-bf49-4d64-bfaa-14ce43475141');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 214, '24jsswl5acmx', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:02:14.932606+00', '2026-03-02 16:02:14.932606+00', NULL, '79eb8d49-de78-43e4-a269-2e73bd9ba965');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 166, '4ermmbtgxsia', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-01 14:26:46.105831+00', '2026-03-02 16:14:58.282681+00', 'u2mkdldbejnw', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 201, 'mgyzcyzvoqj2', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-02 16:00:57.060309+00', '2026-03-02 18:38:21.371765+00', 'ppll6zrsq5cn', 'fe7d0f79-3be6-4799-9bd8-3f7ebfa94246');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 125, 'urp7og3tlezr', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-02-28 15:30:32.850941+00', '2026-03-02 23:53:44.371718+00', NULL, '86378985-942c-4d1c-a858-d2adc5a3173f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 215, 'zyoevcr2juiu', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-02 16:02:14.942236+00', '2026-03-02 16:02:14.942236+00', NULL, 'a7af0387-ff7b-4722-a62f-9153fbd6ec99');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 232, 'awtltls5tctc', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-03 06:15:36.010758+00', '2026-03-03 06:15:36.010758+00', NULL, 'fe70f434-367b-4e36-a64c-fe24b0b8e717');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 287, 'zkwk6iembpy4', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-04 10:03:03.40499+00', '2026-03-04 16:46:47.953084+00', NULL, '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 335, 'cdu7pw36uhdw', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-05 09:57:40.758917+00', '2026-03-06 03:38:55.407101+00', '6xikwto4h34z', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 228, 'ipvpl3472ext', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-02 23:53:44.403659+00', '2026-03-03 09:40:02.712782+00', 'urp7og3tlezr', '86378985-942c-4d1c-a858-d2adc5a3173f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 909, 'illgx5pumtuk', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', false, '2026-03-12 08:36:44.781076+00', '2026-03-12 08:36:44.781076+00', '6dujft55uqvf', 'a20bb4ea-e677-4a3f-bd10-4fd3f57a4648');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 364, 'cj3pzr4vrpnh', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-06 03:38:55.446438+00', '2026-03-06 06:29:56.881327+00', 'cdu7pw36uhdw', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 822, 'uw7eoxlredqv', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:19.935414+00', '2026-03-11 09:39:21.914196+00', 'r52e7hb5gl5t', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 289, 'ujohmx45xxt2', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-04 10:15:21.439485+00', '2026-03-04 17:39:24.938005+00', '5ngok5av7mb5', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 918, '7tevt3nbrhu3', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:00.052517+00', '2026-03-12 09:47:00.468275+00', NULL, '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 332, 'phtija5qjlzi', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-05 09:22:07.304034+00', '2026-03-06 06:30:44.742914+00', 'pzv4jab3vlhk', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 225, 'xx2twiff42h4', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-02 18:38:21.387996+00', '2026-03-02 18:38:21.387996+00', 'mgyzcyzvoqj2', 'fe7d0f79-3be6-4799-9bd8-3f7ebfa94246');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 278, 'r26gzg7s54g2', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-04 09:41:43.588186+00', '2026-03-04 17:51:34.965462+00', NULL, '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 656, 'kjmpeuvzownu', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-10 15:40:08.432237+00', '2026-03-11 09:28:12.25045+00', 'cobys25tnlet', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 216, 'uawt22gi3osr', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-02 16:02:17.437196+00', '2026-03-02 23:47:41.45211+00', NULL, '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 368, 'evxcxqilbaa3', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-06 06:30:44.750718+00', '2026-03-06 07:31:01.900441+00', 'phtija5qjlzi', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 823, 'mkcwpf36z3jn', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:21.922471+00', '2026-03-11 09:39:25.849322+00', 'uw7eoxlredqv', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 303, '7q7csmntz2pa', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-04 17:39:24.956434+00', '2026-03-04 19:06:15.991598+00', 'ujohmx45xxt2', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 329, 'ako7odwdcktk', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-05 08:52:59.015233+00', '2026-03-06 07:58:15.68871+00', 'wamu3srdntkk', '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 824, 'i5zeacxerflj', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:26.094219+00', '2026-03-11 09:39:29.352078+00', 'mkcwpf36z3jn', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 919, 'bgburonlmu2v', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:00.471138+00', '2026-03-12 09:47:02.373927+00', '7tevt3nbrhu3', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 227, 'mxgehzg4w45t', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-02 23:47:41.470694+00', '2026-03-03 17:22:08.682757+00', 'uawt22gi3osr', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 674, 'lyotk7fuhqpq', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-10 18:31:09.219462+00', '2026-03-10 19:47:36.304593+00', 'htyknvbmcgvc', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 455, 'ivlpsseo6nyb', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-07 16:23:32.763228+00', '2026-03-08 10:11:43.41378+00', 'qdfeoskl7anc', '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 825, 'wypqmaemzsc4', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:29.512697+00', '2026-03-11 09:39:31.007303+00', 'i5zeacxerflj', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 381, '3khohmfzzmy4', '08c23b1e-112e-4291-9c0b-551f16632f05', false, '2026-03-06 09:24:34.707782+00', '2026-03-06 09:24:34.707782+00', NULL, 'acaa1c68-5539-4f14-b89e-7c6dc6aa0bf1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 286, 'igri6das3nxw', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', true, '2026-03-04 10:02:35.329411+00', '2026-03-06 09:25:12.09199+00', 'pw62wdlwbcvj', '812df86d-8f84-4c27-b728-a148075555ca');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 826, 'j4hmmbw37y3j', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:31.007799+00', '2026-03-11 09:39:31.635886+00', 'wypqmaemzsc4', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 315, 'nmgb7ekppora', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', true, '2026-03-05 04:18:26.661683+00', '2026-03-06 09:38:36.033657+00', NULL, '6fb0429d-40a1-48cc-a107-a5c218ee99b5');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 371, 'uzzzmvofbhmc', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-06 07:31:01.917963+00', '2026-03-06 10:00:44.394464+00', 'evxcxqilbaa3', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 367, '3jw6dcqay4li', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-06 06:29:56.905311+00', '2026-03-06 10:08:20.527071+00', 'cj3pzr4vrpnh', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 820, 'ln4kcmhaazzh', 'e5540156-8936-4a5c-ab78-4f1b503649f0', true, '2026-03-11 09:39:18.055452+00', '2026-03-11 10:38:22.583338+00', NULL, 'ca021e11-f82d-46df-b68d-6d7ec803b7e7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 217, 'kpzcpl2zutfg', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-02 16:14:58.294189+00', '2026-03-04 06:02:21.993488+00', '4ermmbtgxsia', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 318, '2uu4qtwijcbi', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-05 05:43:46.802232+00', '2026-03-05 05:43:46.802232+00', 'v6xnkf77xnin', '90dc03e3-ae2a-496c-b468-2c033578e6e8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 690, '6kljlj6fz7h2', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-11 06:59:04.744825+00', '2026-03-11 12:18:59.597935+00', '7vdpsdpsvsp2', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 234, 'wuajk3f7l6wg', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-03 09:40:02.73359+00', '2026-03-04 06:33:04.38126+00', 'ipvpl3472ext', '86378985-942c-4d1c-a858-d2adc5a3173f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 263, '3oyk5ernxhmf', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-04 06:02:22.016+00', '2026-03-04 07:56:59.986907+00', 'kpzcpl2zutfg', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 684, 'ziqei4y4p5q4', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-11 05:36:42.145605+00', '2026-03-11 16:47:57.298662+00', 'e4bbzfqszvva', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 308, 'bx23vuwyoh64', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-04 19:06:16.019149+00', '2026-03-05 06:42:37.176267+00', '7q7csmntz2pa', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 285, 'axqtrhzqikuk', '781be76f-8857-4aed-842f-d2ac4acfaa27', false, '2026-03-04 10:01:59.305384+00', '2026-03-04 10:01:59.305384+00', 'pe7vc7j5ah5k', '7b5e59c3-47a7-4e09-8723-01005e95ece4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 269, '5ngok5av7mb5', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-04 07:57:00.011496+00', '2026-03-04 10:15:21.407259+00', '3oyk5ernxhmf', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 313, 'gbfu6ebqtx7o', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-05 04:06:28.013965+00', '2026-03-05 07:22:45.720509+00', 'mkxhb2z23ivc', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 325, 'dfhfntcwmm2i', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-05 07:22:45.740021+00', '2026-03-05 08:48:20.639975+00', 'gbfu6ebqtx7o', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 319, 'wamu3srdntkk', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-05 05:43:46.846762+00', '2026-03-05 08:52:59.006751+00', NULL, '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 279, 'pzv4jab3vlhk', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-04 09:42:35.93084+00', '2026-03-05 09:22:07.289545+00', 'vk4ef67rwizl', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 333, 'il26gcineafo', '5c2531cd-11ef-40f9-9789-10bc77e16808', false, '2026-03-05 09:22:59.157449+00', '2026-03-05 09:22:59.157449+00', NULL, 'd916e10d-7753-483e-9136-ed122851652f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 322, '6xikwto4h34z', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-05 06:42:37.202377+00', '2026-03-05 09:57:40.739971+00', 'bx23vuwyoh64', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 328, '74n3j475yx5w', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-05 08:48:20.658112+00', '2026-03-05 10:11:00.7577+00', 'dfhfntcwmm2i', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 306, 'bggb4isffbw3', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-04 17:53:38.211096+00', '2026-03-05 12:50:03.155849+00', '3lorlcxgoksc', '86378985-942c-4d1c-a858-d2adc5a3173f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 305, 'lvepo45xqrnb', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-04 17:51:34.985438+00', '2026-03-05 17:33:10.308113+00', 'r26gzg7s54g2', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 336, 'wivwadvuhcrl', '5c2531cd-11ef-40f9-9789-10bc77e16808', false, '2026-03-05 10:03:24.627883+00', '2026-03-05 10:03:24.627883+00', NULL, '6d37d23d-7706-47d7-a509-5586f95160b8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 353, 'mafes3awe3sm', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-05 16:38:15.871765+00', '2026-03-06 04:55:31.674341+00', 'oojmommkng2j', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 827, 'zcnf74whw27u', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:31.65825+00', '2026-03-11 09:39:33.119686+00', 'j4hmmbw37y3j', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 910, 'ikqgrgfkgj5a', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-12 08:45:05.605257+00', '2026-03-12 08:45:05.605257+00', 'kl6emlzvzafv', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 393, 'kdqu2dteffts', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-06 10:08:20.543248+00', '2026-03-07 12:17:22.044925+00', '3jw6dcqay4li', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 361, 'zyopo5nhzg2o', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-05 17:33:10.322665+00', '2026-03-06 06:49:46.448932+00', 'lvepo45xqrnb', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 445, '3eyr34tdedee', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', false, '2026-03-07 12:35:57.837156+00', '2026-03-07 12:35:57.837156+00', 'orbdwji2zysr', '664cb064-da97-420d-938a-b010e0b84c64');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 344, 'bmkop6oam4bi', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', false, '2026-03-05 12:50:03.176609+00', '2026-03-05 12:50:03.176609+00', 'bggb4isffbw3', '86378985-942c-4d1c-a858-d2adc5a3173f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 828, 'r3dyukd2sjrq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:33.137959+00', '2026-03-11 09:39:34.265768+00', 'zcnf74whw27u', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 337, 'qrojyrpu7ztu', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-05 10:11:00.77417+00', '2026-03-05 12:54:17.276387+00', '74n3j475yx5w', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 365, 'inxhgu26v6oz', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-06 04:55:31.694129+00', '2026-03-07 14:22:54.090564+00', 'mafes3awe3sm', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 920, 'serd76ks242o', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:02.407678+00', '2026-03-12 09:47:03.437589+00', 'bgburonlmu2v', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 340, 'y3yctm5rpxex', '08c23b1e-112e-4291-9c0b-551f16632f05', true, '2026-03-05 10:16:28.184118+00', '2026-03-05 15:32:58.234476+00', NULL, 'd49eb474-ca18-4fd7-a1d8-db8ce73c69c4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 348, 'cjwualtutivv', '08c23b1e-112e-4291-9c0b-551f16632f05', false, '2026-03-05 15:32:58.253145+00', '2026-03-05 15:32:58.253145+00', 'y3yctm5rpxex', 'd49eb474-ca18-4fd7-a1d8-db8ce73c69c4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 382, 'kdsdubgxfphk', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', true, '2026-03-06 09:25:12.113514+00', '2026-03-07 16:24:46.209452+00', 'igri6das3nxw', '812df86d-8f84-4c27-b728-a148075555ca');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 829, 'fq2s5glpjsui', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:34.270847+00', '2026-03-11 09:39:35.040785+00', 'r3dyukd2sjrq', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 421, 'rwcwxb2flfm5', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', true, '2026-03-06 16:28:47.866883+00', '2026-03-09 10:07:20.026639+00', NULL, '666ddd72-dc90-4603-a516-6ee6f09a558f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 347, 'oojmommkng2j', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-05 15:23:37.482163+00', '2026-03-05 16:38:15.848716+00', 'iw2gtr3ggnvg', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 830, 'hbcvdyq5luea', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:35.091765+00', '2026-03-11 09:39:36.245295+00', 'fq2s5glpjsui', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 831, 'n4yy4vyd4gt7', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:36.245723+00', '2026-03-11 09:39:36.614847+00', 'hbcvdyq5luea', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 446, '5uad5ctrkvlb', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-07 12:36:18.716058+00', '2026-03-07 17:26:27.204098+00', NULL, '4faa9291-e18c-4de9-905c-2808c78bb264');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 832, 'jq4hhy7t7c4y', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:36.617757+00', '2026-03-11 09:39:37.484496+00', 'n4yy4vyd4gt7', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 392, 'uyuw7p7s2fm2', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-06 10:00:44.411922+00', '2026-03-09 03:32:08.954497+00', 'uzzzmvofbhmc', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 400, 'ulbuvepyiwpu', '7d38a189-b1d5-401e-aba2-36824936da29', true, '2026-03-06 11:29:01.042836+00', '2026-03-10 08:30:34.989508+00', '5lykqa7thyba', '0e2bcd34-2a6a-4917-af86-4ab5970d2fd2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 833, 'pqjcecqfz3dx', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:37.501473+00', '2026-03-11 09:39:39.248836+00', 'jq4hhy7t7c4y', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 388, 'odeccf2457qw', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', false, '2026-03-06 09:38:36.044238+00', '2026-03-06 09:38:36.044238+00', 'nmgb7ekppora', '6fb0429d-40a1-48cc-a107-a5c218ee99b5');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 834, 'rit6dbtmubmw', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:39.249127+00', '2026-03-11 09:39:39.670887+00', 'pqjcecqfz3dx', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 346, '5frslbj7mfvx', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-05 12:54:17.288244+00', '2026-03-06 09:53:58.988094+00', 'qrojyrpu7ztu', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 658, 'hqpqunw7zshj', '66dc3746-cc17-4afc-b67b-17a4eda74e12', true, '2026-03-10 15:40:34.983521+00', '2026-03-11 03:22:40.298558+00', NULL, '0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 835, 'u4ghszmeg26k', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:39.671203+00', '2026-03-11 09:39:39.869779+00', 'rit6dbtmubmw', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 836, 'tzjh4sx3qtrq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:39.870944+00', '2026-03-11 09:39:40.083341+00', 'u4ghszmeg26k', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 680, '66f5pn4zvcid', '66dc3746-cc17-4afc-b67b-17a4eda74e12', true, '2026-03-11 03:22:40.326166+00', '2026-03-11 08:02:17.47107+00', 'hqpqunw7zshj', '0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 837, 'synxjdwyzadr', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:40.08376+00', '2026-03-11 09:39:40.322579+00', 'tzjh4sx3qtrq', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 396, '5lykqa7thyba', '7d38a189-b1d5-401e-aba2-36824936da29', true, '2026-03-06 10:24:26.768804+00', '2026-03-06 11:29:01.023539+00', 'ddma3j2bawtf', '0e2bcd34-2a6a-4917-af86-4ab5970d2fd2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 838, 'zcari725vz23', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:40.32291+00', '2026-03-11 09:39:40.687548+00', 'synxjdwyzadr', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 839, 'z4erspbbmfkn', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:40.688099+00', '2026-03-11 09:39:41.083396+00', 'zcari725vz23', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 840, 'todd4iiw4aef', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:41.083838+00', '2026-03-11 09:39:41.408717+00', 'z4erspbbmfkn', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 841, 'vtjkn7ibh2ix', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:41.409552+00', '2026-03-11 09:39:41.671971+00', 'todd4iiw4aef', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 345, 'zn336k3upb2b', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-05 12:50:20.565377+00', '2026-03-06 13:04:37.291488+00', NULL, '664cb064-da97-420d-938a-b010e0b84c64');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 372, '66jii2ocn5jd', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-06 07:58:15.705308+00', '2026-03-06 13:11:43.578016+00', 'ako7odwdcktk', '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 842, 'pcey3x3taj52', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:41.672591+00', '2026-03-11 09:39:41.916959+00', 'vtjkn7ibh2ix', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 843, 'ujdnumpop3lb', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:41.917281+00', '2026-03-11 09:39:42.203774+00', 'pcey3x3taj52', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 844, 'aisgfotalgae', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:42.204177+00', '2026-03-11 09:39:42.656496+00', 'ujdnumpop3lb', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 685, 'fhxam3djs44j', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-11 06:15:03.79198+00', '2026-03-11 12:36:34.885843+00', 'tedehulobrmk', '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 708, 'cwfgmwrcbeqq', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-11 09:28:12.277354+00', '2026-03-12 03:26:27.654899+00', 'kjmpeuvzownu', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 389, '72kluj4yhqhs', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', true, '2026-03-06 09:38:55.526258+00', '2026-03-06 16:28:43.449707+00', NULL, '8de9e949-9b8c-4bf0-8085-a16d19877804');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 420, 'usxi4ihk6ill', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', false, '2026-03-06 16:28:43.463569+00', '2026-03-06 16:28:43.463569+00', '72kluj4yhqhs', '8de9e949-9b8c-4bf0-8085-a16d19877804');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 405, 'i4j3cpst6mr4', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-06 13:04:37.361282+00', '2026-03-06 19:18:04.992841+00', 'zn336k3upb2b', '664cb064-da97-420d-938a-b010e0b84c64');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 406, 'byigz5m6ohhe', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-06 13:11:43.591074+00', '2026-03-07 02:42:03.463384+00', '66jii2ocn5jd', '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 391, 'jyw4woyhjqsh', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-06 09:53:59.01082+00', '2026-03-07 02:50:44.302167+00', '5frslbj7mfvx', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 383, '7xlue7llhpik', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', true, '2026-03-06 09:28:59.566324+00', '2026-03-09 09:15:14.504446+00', NULL, 'ff2cd62f-f762-403d-b73d-048f6af1fdb8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 433, '4gqpmrfip5qn', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-07 02:50:53.816984+00', '2026-03-07 09:39:06.642686+00', NULL, 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 429, 'orbdwji2zysr', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-06 19:18:05.014549+00', '2026-03-07 12:35:57.818038+00', 'i4j3cpst6mr4', '664cb064-da97-420d-938a-b010e0b84c64');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 432, 'bxe62zt5s7ae', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', false, '2026-03-07 02:50:44.325227+00', '2026-03-07 02:50:44.325227+00', 'jyw4woyhjqsh', '03fba9ba-31f8-4cb2-89b7-c496b0e79935');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 544, 'tm753gyb5sz3', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', false, '2026-03-09 09:15:14.529167+00', '2026-03-09 09:15:14.529167+00', '7xlue7llhpik', 'ff2cd62f-f762-403d-b73d-048f6af1fdb8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 870, 'jbf7p6w67so4', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-11 12:36:34.901828+00', '2026-03-12 09:03:27.684027+00', 'fhxam3djs44j', '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 845, 'kekdtffbhg2c', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:42.657687+00', '2026-03-11 09:39:42.918435+00', 'aisgfotalgae', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 439, 'zn6zo4owk7c5', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-07 06:54:30.584477+00', '2026-03-07 15:15:57.680998+00', 'deuxedjsauc2', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 905, 'gc7wca5byyi7', 'e5540156-8936-4a5c-ab78-4f1b503649f0', true, '2026-03-12 07:51:17.50007+00', '2026-03-12 09:26:56.538576+00', 'vyt7qgu5avsa', 'd3bef874-b76a-46f9-9524-a3539551e1f8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 549, 'prt6mjnb2p6f', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', true, '2026-03-09 10:07:20.053758+00', '2026-03-11 09:08:43.152515+00', 'rwcwxb2flfm5', '666ddd72-dc90-4603-a516-6ee6f09a558f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 431, 'qea6kgg7iwyo', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-07 02:42:03.487665+00', '2026-03-07 07:13:03.961826+00', 'byigz5m6ohhe', '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 846, '6wbszl3dlzpf', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:42.918857+00', '2026-03-11 09:39:43.116302+00', 'kekdtffbhg2c', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 892, 't3fzgvrzi36y', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-12 03:38:20.905615+00', '2026-03-12 09:37:22.226314+00', 'zoafd3o537ec', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 440, 'qdfeoskl7anc', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-07 07:13:03.984755+00', '2026-03-07 16:23:32.748958+00', 'qea6kgg7iwyo', '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 443, '77dnmgyh3txu', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-07 12:17:22.061514+00', '2026-03-07 16:26:15.690004+00', 'kdqu2dteffts', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 847, 'tfzimflbzd3a', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:43.116685+00', '2026-03-11 09:39:43.336074+00', '6wbszl3dlzpf', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 921, '7ys7glzftztg', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:03.438208+00', '2026-03-12 09:47:03.878648+00', 'serd76ks242o', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 848, 'ifanstannozs', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:43.336414+00', '2026-03-11 09:39:43.82011+00', 'tfzimflbzd3a', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 849, 'od2ofypaewhr', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:43.820462+00', '2026-03-11 09:39:44.211274+00', 'ifanstannozs', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 922, 'oa4ybzpazu3q', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:03.87905+00', '2026-03-12 09:47:04.193171+00', '7ys7glzftztg', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 547, 'hioqjyx757h5', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-09 09:50:27.671316+00', '2026-03-09 13:09:56.333737+00', 'rpvthbh7wjjd', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 850, 'cdw42tojwf5p', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:44.212612+00', '2026-03-11 09:39:44.433594+00', 'od2ofypaewhr', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 464, 'j4fhlld5sto6', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', false, '2026-03-07 17:26:31.211138+00', '2026-03-07 17:26:31.211138+00', NULL, 'af4c298a-288a-460a-b53a-f2d46008f86a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 851, 'cqglbdtihuo3', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:44.434015+00', '2026-03-11 09:39:44.641618+00', 'cdw42tojwf5p', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 923, '76fdvnriu3hd', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:04.193666+00', '2026-03-12 09:47:05.103095+00', 'oa4ybzpazu3q', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 852, 'jjetd766zhhp', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:44.641937+00', '2026-03-11 09:39:47.703417+00', 'cqglbdtihuo3', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 564, 'qp5cofqt4vmq', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-09 13:09:56.357786+00', '2026-03-10 00:43:15.221981+00', 'hioqjyx757h5', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 470, 'y7qnqm2dy6p5', '08a46873-b1cf-4b3e-92b2-37e662a11775', false, '2026-03-07 18:01:41.983839+00', '2026-03-07 18:01:41.983839+00', NULL, 'd55783f9-a875-454b-97cd-e3957b966821');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 457, 'xg43r6lq6p2n', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-07 16:26:15.697404+00', '2026-03-07 18:01:56.416718+00', '77dnmgyh3txu', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 659, 'd5wuseqnzryb', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', true, '2026-03-10 15:44:26.181617+00', '2026-03-11 14:31:23.672605+00', 'jyxff46ovzwh', '8e45b52c-3ca9-449c-a6bd-00d5dfaaf1c4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 471, 'hbfz4pijiz3t', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-07 18:01:56.421079+00', '2026-03-10 03:34:16.965998+00', 'xg43r6lq6p2n', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 924, 'ttzj4xin24h5', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:05.103603+00', '2026-03-12 09:47:05.381317+00', '76fdvnriu3hd', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 456, 's4uy4lanxlbj', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', true, '2026-03-07 16:24:46.222825+00', '2026-03-11 17:49:25.63431+00', 'kdsdubgxfphk', '812df86d-8f84-4c27-b728-a148075555ca');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 878, '6dl45zqq7fwn', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-11 17:38:49.658752+00', '2026-03-11 18:37:52.449212+00', 'qniaxdvik4ar', '3fca260f-e54d-4c9f-9a6f-0ba32894f5ea');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 925, '3p4rxuexxai4', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:05.381895+00', '2026-03-12 09:47:06.138697+00', 'ttzj4xin24h5', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 463, 'vx5xio3schu2', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-07 17:26:27.212674+00', '2026-03-07 18:41:37.79978+00', '5uad5ctrkvlb', '4faa9291-e18c-4de9-905c-2808c78bb264');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 886, 'jhferkpdsik6', '66dc3746-cc17-4afc-b67b-17a4eda74e12', false, '2026-03-12 02:18:14.686229+00', '2026-03-12 02:18:14.686229+00', 'sbexklilviqc', '0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 866, 'm22q5nrweu5q', 'e5540156-8936-4a5c-ab78-4f1b503649f0', true, '2026-03-11 10:36:13.692964+00', '2026-03-12 03:39:14.957872+00', NULL, 'd3bef874-b76a-46f9-9524-a3539551e1f8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 897, 'cy5pik235pbm', '805ab41a-0b79-4e31-b0d2-072a072a443b', false, '2026-03-12 04:16:55.697057+00', '2026-03-12 04:16:55.697057+00', '5via3owxhaby', '348223b8-a885-4548-b609-0811ce2224bd');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 893, '5sskc4xz4d2i', 'e5540156-8936-4a5c-ab78-4f1b503649f0', true, '2026-03-12 03:39:14.9891+00', '2026-03-12 05:15:55.503602+00', 'm22q5nrweu5q', 'd3bef874-b76a-46f9-9524-a3539551e1f8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 882, '6dsgavhhwkdl', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-11 18:37:52.475042+00', '2026-03-12 05:53:41.979801+00', '6dl45zqq7fwn', '3fca260f-e54d-4c9f-9a6f-0ba32894f5ea');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 454, 'yidh46ssjdhu', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-07 16:21:12.294263+00', '2026-03-08 01:42:14.659275+00', 'kh6qm7g3tuws', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 926, 'ze2qpes36mox', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:06.139104+00', '2026-03-12 09:47:06.55715+00', '3p4rxuexxai4', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 901, 'wg7f5k3yepxo', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-12 05:53:42.00044+00', '2026-03-12 06:52:14.126779+00', '6dsgavhhwkdl', '3fca260f-e54d-4c9f-9a6f-0ba32894f5ea');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 911, 'jawkvgjuzixe', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-12 09:03:27.717339+00', '2026-03-12 13:01:03.711959+00', 'jbf7p6w67so4', '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 451, 'yqwprr4jsb26', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-07 14:22:54.111031+00', '2026-03-08 03:47:08.969561+00', 'inxhgu26v6oz', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 485, 'oujaelsbakww', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-08 03:47:08.982543+00', '2026-03-08 06:10:22.039962+00', 'yqwprr4jsb26', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 477, 'g5ix43mewubc', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-07 18:41:37.818215+00', '2026-03-08 06:40:48.670307+00', 'vx5xio3schu2', '4faa9291-e18c-4de9-905c-2808c78bb264');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 474, 'boxl243j5ks5', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-07 18:15:02.46297+00', '2026-03-08 06:41:28.050934+00', '66akp3a2dde3', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 481, '22e2hdggcoqi', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-08 01:42:14.678043+00', '2026-03-08 23:46:09.772793+00', 'yidh46ssjdhu', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 523, 'jyxff46ovzwh', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', true, '2026-03-08 16:51:06.874801+00', '2026-03-10 15:44:26.153701+00', 't5zua7mjg2fp', '8e45b52c-3ca9-449c-a6bd-00d5dfaaf1c4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 871, 'io5z5phb3ctc', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', true, '2026-03-11 14:31:23.693751+00', '2026-03-12 08:08:15.229008+00', 'd5wuseqnzryb', '8e45b52c-3ca9-449c-a6bd-00d5dfaaf1c4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 495, 'bs66sqgwwxup', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', false, '2026-03-08 06:40:48.687887+00', '2026-03-08 06:40:48.687887+00', 'g5ix43mewubc', '4faa9291-e18c-4de9-905c-2808c78bb264');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 898, '6dujft55uqvf', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', true, '2026-03-12 04:54:35.993831+00', '2026-03-12 08:36:44.762587+00', '73bm3imfl2n7', 'a20bb4ea-e677-4a3f-bd10-4fd3f57a4648');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 853, 'pb7wmdhk7uqm', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:47.704705+00', '2026-03-11 09:39:47.901894+00', 'jjetd766zhhp', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 529, 'rpvthbh7wjjd', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-09 01:29:49.211036+00', '2026-03-09 09:50:27.658202+00', 'fwdrydwku5k5', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 912, 'evqpprqinb3s', 'e5540156-8936-4a5c-ab78-4f1b503649f0', false, '2026-03-12 09:26:56.558013+00', '2026-03-12 09:26:56.558013+00', 'gc7wca5byyi7', 'd3bef874-b76a-46f9-9524-a3539551e1f8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 854, 'dezmlratyi6f', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:47.903502+00', '2026-03-11 09:39:48.104973+00', 'pb7wmdhk7uqm', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 499, 'ri4gqiibmpqh', '08a46873-b1cf-4b3e-92b2-37e662a11775', true, '2026-03-08 07:33:53.738559+00', '2026-03-08 08:32:36.780381+00', NULL, '32a73cb8-db9d-440d-be68-464ffc13c02a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 855, 'fhx277w7pvos', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:48.105302+00', '2026-03-11 09:39:48.686979+00', 'dezmlratyi6f', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 927, 'ih4vvkm2im7v', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:06.558748+00', '2026-03-12 09:47:07.043353+00', 'ze2qpes36mox', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 856, 'as4yr3obistu', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:48.691674+00', '2026-03-11 09:39:49.037354+00', 'fhx277w7pvos', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 504, 'fc7uqoqnt63z', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-08 10:11:43.4369+00', '2026-03-08 10:11:43.4369+00', 'ivlpsseo6nyb', '2df65f47-ebf2-489f-8ccc-a482e6972efe');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 496, '2zdb3whh4kco', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-08 06:40:49.448195+00', '2026-03-08 10:29:14.31325+00', NULL, '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 857, 'rsxvagcnevpr', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:49.038953+00', '2026-03-11 09:39:49.237171+00', 'as4yr3obistu', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 928, 'wduudycjx5kv', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:07.04495+00', '2026-03-12 09:47:07.414316+00', 'ih4vvkm2im7v', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 501, 'o64x5v5iw4ql', '08a46873-b1cf-4b3e-92b2-37e662a11775', true, '2026-03-08 08:32:36.7947+00', '2026-03-08 11:07:32.398927+00', 'ri4gqiibmpqh', '32a73cb8-db9d-440d-be68-464ffc13c02a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 858, '2cz43rq2i3fo', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:49.237518+00', '2026-03-11 09:39:49.452968+00', 'rsxvagcnevpr', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 859, 'ax32w3hd2tuq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-11 09:39:49.454174+00', '2026-03-11 09:39:49.809843+00', '2cz43rq2i3fo', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 860, 'aepk4izrgosm', '4cb50b66-b09c-4b38-8091-4965a170c788', false, '2026-03-11 09:39:49.810152+00', '2026-03-11 09:39:49.810152+00', 'ax32w3hd2tuq', 'c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 867, 'gv4sge2adbwy', 'e5540156-8936-4a5c-ab78-4f1b503649f0', false, '2026-03-11 10:38:22.601078+00', '2026-03-11 10:38:22.601078+00', 'ln4kcmhaazzh', 'ca021e11-f82d-46df-b68d-6d7ec803b7e7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 494, '7tnwcotx3sre', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-08 06:10:22.057971+00', '2026-03-08 12:18:46.936584+00', 'oujaelsbakww', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 929, 'sftco5ayc2f5', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:07.414711+00', '2026-03-12 09:47:07.913586+00', 'wduudycjx5kv', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 513, 'xlixvkfwn7ad', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-08 12:18:46.952963+00', '2026-03-08 14:28:02.41329+00', '7tnwcotx3sre', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 875, 'qniaxdvik4ar', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-11 16:28:04.334299+00', '2026-03-11 17:38:49.637079+00', NULL, '3fca260f-e54d-4c9f-9a6f-0ba32894f5ea');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 879, 'ea6xfw3nkp26', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', false, '2026-03-11 17:49:25.644542+00', '2026-03-11 17:49:25.644542+00', 's4uy4lanxlbj', '812df86d-8f84-4c27-b728-a148075555ca');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 508, 'cycqeslnxyif', '08a46873-b1cf-4b3e-92b2-37e662a11775', true, '2026-03-08 11:07:32.421266+00', '2026-03-08 15:12:48.964585+00', 'o64x5v5iw4ql', '32a73cb8-db9d-440d-be68-464ffc13c02a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 883, 'z4ponjpn5m3s', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', false, '2026-03-11 21:17:21.344808+00', '2026-03-11 21:17:21.344808+00', NULL, '0004f6b4-6d70-408c-9371-6744d219688d');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 506, 'knubbpggr5e4', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-08 10:29:14.330698+00', '2026-03-09 12:43:20.278971+00', '2zdb3whh4kco', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 676, 'e4bbzfqszvva', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-10 19:47:36.322806+00', '2026-03-11 05:36:42.117606+00', 'lyotk7fuhqpq', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 930, 'mzu4w7g3trkx', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:07.914236+00', '2026-03-12 09:47:08.291514+00', 'sftco5ayc2f5', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 931, 'h2vjz6i7o3s3', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:08.295491+00', '2026-03-12 09:47:09.457624+00', 'mzu4w7g3trkx', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 894, '73bm3imfl2n7', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', true, '2026-03-12 03:56:19.303023+00', '2026-03-12 04:54:35.965996+00', 'yoe3e53kicyy', 'a20bb4ea-e677-4a3f-bd10-4fd3f57a4648');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 517, '5l3u3o2snlzp', '08a46873-b1cf-4b3e-92b2-37e662a11775', true, '2026-03-08 15:12:48.980113+00', '2026-03-11 07:51:49.001758+00', 'cycqeslnxyif', '32a73cb8-db9d-440d-be68-464ffc13c02a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 516, 't5zua7mjg2fp', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', true, '2026-03-08 14:32:39.591698+00', '2026-03-08 16:51:06.699227+00', NULL, '8e45b52c-3ca9-449c-a6bd-00d5dfaaf1c4');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 692, 'sw7qrlldkibc', '08a46873-b1cf-4b3e-92b2-37e662a11775', false, '2026-03-11 07:51:49.016505+00', '2026-03-11 07:51:49.016505+00', '5l3u3o2snlzp', '32a73cb8-db9d-440d-be68-464ffc13c02a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 902, 'ew5fydutdft5', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', false, '2026-03-12 06:02:01.406687+00', '2026-03-12 06:02:01.406687+00', 'ea4fyasxuwby', '98378a67-f2e0-4698-9fc6-ed86603c3d2a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 515, 'bgmh4aisc5ye', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-08 14:28:02.428113+00', '2026-03-09 15:40:48.11124+00', 'xlixvkfwn7ad', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 932, 'zaemcnipw4kr', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:47:09.458173+00', '2026-03-12 09:47:11.491466+00', 'h2vjz6i7o3s3', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 933, 'ftzrr2jx6d42', '4cb50b66-b09c-4b38-8091-4965a170c788', false, '2026-03-12 09:47:11.541475+00', '2026-03-12 09:47:11.541475+00', 'zaemcnipw4kr', '597bf3e7-3932-4548-a4c7-f11fdaee2a0c');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 528, 'fwdrydwku5k5', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-08 23:46:09.791484+00', '2026-03-09 01:29:49.194522+00', '22e2hdggcoqi', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 981, 'rx346wvspfmm', '781be76f-8857-4aed-842f-d2ac4acfaa27', false, '2026-03-12 10:18:38.886641+00', '2026-03-12 10:18:38.886641+00', 'yq3o5q6bqto2', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 907, 'ddxu3hju6xvj', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-12 08:02:00.075724+00', '2026-03-12 11:14:05.985363+00', 'jdmidj6iqhbm', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 531, 'owmotgchokqj', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-09 03:32:08.969537+00', '2026-03-09 04:32:22.881793+00', 'uyuw7p7s2fm2', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 571, 'mmfvcfghvxhf', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-09 15:40:48.135317+00', '2026-03-09 16:54:28.308707+00', 'bgmh4aisc5ye', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 563, 'tz7zzlyif7e3', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-09 12:43:20.293605+00', '2026-03-09 17:40:36.361504+00', 'knubbpggr5e4', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 540, 'n3zingshv3im', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-09 04:32:22.897167+00', '2026-03-10 05:45:42.427284+00', 'owmotgchokqj', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 505, 'ze567w5t7vli', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-08 10:12:42.039224+00', '2026-03-10 07:30:56.104583+00', NULL, 'd96f5a0c-5e88-4e0e-a4b7-884191afe5ed');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 497, '62m34y3gkmwv', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-08 06:41:28.064477+00', '2026-03-10 07:36:29.689477+00', 'boxl243j5ks5', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 583, 'xqyx2snyou5p', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-09 16:54:28.322666+00', '2026-03-10 09:33:16.524854+00', 'mmfvcfghvxhf', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 638, 'cobys25tnlet', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-10 11:42:41.048658+00', '2026-03-10 15:40:08.423439+00', 'sgu64xodhryp', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 702, 'hzg253dspsby', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', false, '2026-03-11 09:08:43.169539+00', '2026-03-11 09:08:43.169539+00', 'prt6mjnb2p6f', '666ddd72-dc90-4603-a516-6ee6f09a558f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 643, '3h6lzmoztg7m', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-10 12:28:01.493896+00', '2026-03-10 16:02:01.774057+00', 'ae3ro7xxhw7j', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 618, 'kl6emlzvzafv', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-10 06:57:17.499817+00', '2026-03-12 08:45:05.584299+00', 'n56o3ppfzgw4', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 899, 'jay2jf4c6prl', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', true, '2026-03-12 05:14:52.647649+00', '2026-03-12 09:34:23.362672+00', 'yqk4ii62gwom', 'f403d187-b910-495a-a3a6-46678bd444dd');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 623, 'htyknvbmcgvc', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-10 07:40:42.889785+00', '2026-03-10 18:31:09.176751+00', '3irxpxavl332', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 913, 'ctqr26xmlzkb', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', false, '2026-03-12 09:34:23.51663+00', '2026-03-12 09:34:23.51663+00', 'jay2jf4c6prl', 'f403d187-b910-495a-a3a6-46678bd444dd');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 693, 'sngoauthgtga', '66dc3746-cc17-4afc-b67b-17a4eda74e12', true, '2026-03-11 08:02:17.481479+00', '2026-03-11 15:09:12.177879+00', '66f5pn4zvcid', '0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 649, 'uvp6bjds42pl', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-10 14:49:11.328982+00', '2026-03-11 02:58:00.055143+00', 'sgfimcjuwfe5', '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 914, 'kri2aaytbvwo', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', false, '2026-03-12 09:34:30.079192+00', '2026-03-12 09:34:30.079192+00', NULL, '75f843a2-1284-4801-bb5f-7f275d4dd457');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 876, 'xxqkc3bfcvtf', '66dc3746-cc17-4afc-b67b-17a4eda74e12', true, '2026-03-11 16:36:11.226457+00', '2026-03-11 18:05:07.581376+00', 'pp5wnewstpof', '0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 635, 'r7iyoy4n5bau', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-10 10:09:59.149359+00', '2026-03-12 09:40:18.764059+00', 'rsosezkmsp7t', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 934, 'flvzo3oxrjav', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:05.207835+00', '2026-03-12 09:48:05.898495+00', NULL, '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 880, 'sbexklilviqc', '66dc3746-cc17-4afc-b67b-17a4eda74e12', true, '2026-03-11 18:05:07.994384+00', '2026-03-12 02:18:14.500602+00', 'xxqkc3bfcvtf', '0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 935, 'xzsqxbxvydkz', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:05.902902+00', '2026-03-12 09:48:10.17835+00', 'flvzo3oxrjav', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 890, 'yoe3e53kicyy', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', true, '2026-03-12 02:53:58.441877+00', '2026-03-12 03:56:19.28651+00', NULL, 'a20bb4ea-e677-4a3f-bd10-4fd3f57a4648');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 895, 'mhvet7hvfj5n', '5c5a6e76-6682-4405-bad4-32817d63619e', false, '2026-03-12 03:58:33.290777+00', '2026-03-12 03:58:33.290777+00', NULL, '6c491caf-bbdc-46ec-976d-82e593918525');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 884, 'yqk4ii62gwom', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', true, '2026-03-12 02:12:51.472969+00', '2026-03-12 05:14:52.619575+00', NULL, 'f403d187-b910-495a-a3a6-46678bd444dd');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 604, 'mtvypuf3siwg', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-10 03:34:16.981379+00', '2026-03-10 05:06:16.851723+00', 'hbfz4pijiz3t', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 624, 'ea4fyasxuwby', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', true, '2026-03-10 07:56:34.339433+00', '2026-03-12 06:02:01.387106+00', NULL, '98378a67-f2e0-4698-9fc6-ed86603c3d2a');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 626, 'jdmidj6iqhbm', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-10 08:35:39.489813+00', '2026-03-12 08:01:59.063613+00', 'legdc6fhslsr', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 936, 'hg3n66hu75xy', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:10.289877+00', '2026-03-12 09:48:14.681644+00', 'xzsqxbxvydkz', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 937, 'ilxai67lyvly', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:15.370878+00', '2026-03-12 09:48:23.504899+00', 'hg3n66hu75xy', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 938, 'iv62w6wqpqea', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:23.560503+00', '2026-03-12 09:48:29.177325+00', 'ilxai67lyvly', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 939, 'exozlllzt3fe', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:29.459209+00', '2026-03-12 09:48:38.401678+00', 'iv62w6wqpqea', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 940, 'me7mavajfzjo', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:38.42515+00', '2026-03-12 09:48:40.831167+00', 'exozlllzt3fe', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 607, 'smu7k2qmyr73', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-10 05:06:16.879182+00', '2026-03-10 06:26:29.477537+00', 'mtvypuf3siwg', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 595, 'n56o3ppfzgw4', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', true, '2026-03-10 00:43:15.248889+00', '2026-03-10 06:57:17.481087+00', 'qp5cofqt4vmq', 'a9cb4a50-76dd-4ffa-9598-272834953588');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 941, 'kzaqjgent7m6', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:40.832198+00', '2026-03-12 09:48:41.741906+00', 'me7mavajfzjo', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 942, 'onns24rwtdza', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:41.762715+00', '2026-03-12 09:48:43.289915+00', 'kzaqjgent7m6', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 943, 'daxexqdhkgit', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:43.332224+00', '2026-03-12 09:48:44.448841+00', 'onns24rwtdza', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 617, '3irxpxavl332', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-10 06:26:29.504751+00', '2026-03-10 07:40:42.873266+00', 'smu7k2qmyr73', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 944, 'a56dujfpu4yr', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:44.449906+00', '2026-03-12 09:48:45.066877+00', 'daxexqdhkgit', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 625, '3bswwmc3ybo2', '7d38a189-b1d5-401e-aba2-36824936da29', false, '2026-03-10 08:30:35.009077+00', '2026-03-10 08:30:35.009077+00', 'ulbuvepyiwpu', '0e2bcd34-2a6a-4917-af86-4ab5970d2fd2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 622, 'legdc6fhslsr', '79ea6f3c-4bff-404b-9539-8b64a36a919b', true, '2026-03-10 07:36:29.710834+00', '2026-03-10 08:35:39.474512+00', '62m34y3gkmwv', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 621, '3roqngs4yxyv', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-10 07:30:56.123569+00', '2026-03-10 08:49:58.017717+00', 'ze567w5t7vli', 'd96f5a0c-5e88-4e0e-a4b7-884191afe5ed');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 627, 'uqr6ufcgb3hg', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-10 08:49:58.036191+00', '2026-03-10 08:49:58.036191+00', '3roqngs4yxyv', 'd96f5a0c-5e88-4e0e-a4b7-884191afe5ed');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 945, 'perdx7jntqwb', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:45.069328+00', '2026-03-12 09:48:45.70226+00', 'a56dujfpu4yr', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 946, 'hpjim2an2u4q', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:45.703068+00', '2026-03-12 09:48:46.026165+00', 'perdx7jntqwb', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 947, '3fzkb5hqtolf', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:46.026671+00', '2026-03-12 09:48:46.285555+00', 'hpjim2an2u4q', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 948, 'jzax744cbdev', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:46.287197+00', '2026-03-12 09:48:46.668484+00', '3fzkb5hqtolf', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 949, 'bbgzkq25yb3v', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:46.66902+00', '2026-03-12 09:48:46.963775+00', 'jzax744cbdev', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 614, 'rsosezkmsp7t', '5c2531cd-11ef-40f9-9789-10bc77e16808', true, '2026-03-10 05:45:42.433574+00', '2026-03-10 10:09:59.13379+00', 'n3zingshv3im', 'fd621fa3-5b30-4fe6-bc46-620173a269b2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 950, 'umaw4h45eep6', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:46.964093+00', '2026-03-12 09:48:47.383493+00', 'bbgzkq25yb3v', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 868, 'kcznea3v53ll', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-11 11:13:48.850299+00', '2026-03-12 11:59:26.966601+00', '27plhvc3aaqc', '51edfdb8-a720-4ace-b01e-745773828af6');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 632, 'sgu64xodhryp', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-10 09:33:16.544263+00', '2026-03-10 11:42:41.014389+00', 'xqyx2snyou5p', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 903, 'gxq47lqkvxm4', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-12 06:29:52.017754+00', '2026-03-12 13:52:54.698894+00', '63xuqw7cxeoe', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 587, 'ae3ro7xxhw7j', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-09 17:40:36.376037+00', '2026-03-10 12:28:01.476281+00', 'tz7zzlyif7e3', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 634, 'pl4xrbwgats7', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-10 09:55:22.342826+00', '2026-03-10 13:06:15.942303+00', NULL, '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 644, 'sgfimcjuwfe5', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-10 13:06:15.963344+00', '2026-03-10 14:49:11.30925+00', 'pl4xrbwgats7', '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 915, 'dcnonuqatark', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', false, '2026-03-12 09:37:22.27985+00', '2026-03-12 09:37:22.27985+00', 't3fzgvrzi36y', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 863, '2uygo6surt3h', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', false, '2026-03-11 10:14:20.762291+00', '2026-03-11 10:14:20.762291+00', NULL, '8ab9f851-b08b-4efb-bc95-5250aff059f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 864, '27plhvc3aaqc', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-11 10:15:10.151314+00', '2026-03-11 11:13:48.831169+00', NULL, '51edfdb8-a720-4ace-b01e-745773828af6');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 951, 'tcxzjxlktkz5', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:47.38397+00', '2026-03-12 09:48:47.828953+00', 'umaw4h45eep6', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 678, 'tedehulobrmk', '71d95693-e5e9-4626-85fc-4a90e261b5b1', true, '2026-03-11 02:58:00.074081+00', '2026-03-11 06:15:03.741235+00', 'uvp6bjds42pl', '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 873, 'pp5wnewstpof', '66dc3746-cc17-4afc-b67b-17a4eda74e12', true, '2026-03-11 15:09:12.199824+00', '2026-03-11 16:36:11.193337+00', 'sngoauthgtga', '0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 662, '7vdpsdpsvsp2', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-10 16:02:01.788289+00', '2026-03-11 06:59:04.724111+00', '3h6lzmoztg7m', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 952, 'rbpxp7vywmza', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:47.829278+00', '2026-03-12 09:48:48.179605+00', 'tcxzjxlktkz5', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 877, 'ybi2giewklvc', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-11 16:47:57.312215+00', '2026-03-11 18:09:37.642147+00', 'ziqei4y4p5q4', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 695, 'gefp6qehffez', 'c551abc6-369e-4722-8a1f-f442501db0a2', false, '2026-03-11 08:15:55.779815+00', '2026-03-11 08:15:55.779815+00', NULL, 'eff59d0d-1e66-43ad-aa43-7a3639b7a649');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 885, 'n6lch2oauyxn', '66dc3746-cc17-4afc-b67b-17a4eda74e12', false, '2026-03-12 02:18:14.650675+00', '2026-03-12 02:18:14.650675+00', NULL, 'e07d8672-d6c7-4f89-b493-d69af60bb784');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 881, 'zoafd3o537ec', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', true, '2026-03-11 18:09:37.662927+00', '2026-03-12 03:38:20.887733+00', 'ybi2giewklvc', '27cbf38c-9108-4eb4-a081-16d6f7982021');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 953, 'fl2p3s7yw7v5', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:48.18058+00', '2026-03-12 09:48:48.573975+00', 'rbpxp7vywmza', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 862, '5via3owxhaby', '805ab41a-0b79-4e31-b0d2-072a072a443b', true, '2026-03-11 10:13:42.200914+00', '2026-03-12 04:16:55.678495+00', NULL, '348223b8-a885-4548-b609-0811ce2224bd');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 869, '63xuqw7cxeoe', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', true, '2026-03-11 12:18:59.612816+00', '2026-03-12 06:29:52.005036+00', '6kljlj6fz7h2', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 900, 'vyt7qgu5avsa', 'e5540156-8936-4a5c-ab78-4f1b503649f0', true, '2026-03-12 05:15:55.537841+00', '2026-03-12 07:51:17.472982+00', '5sskc4xz4d2i', 'd3bef874-b76a-46f9-9524-a3539551e1f8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 954, '6vr5sx6b22mz', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:48.574762+00', '2026-03-12 09:48:48.827628+00', 'fl2p3s7yw7v5', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 955, 'p6vbdwktgvfq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:48.828818+00', '2026-03-12 09:48:49.080453+00', '6vr5sx6b22mz', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 956, 'ua7tnvq3ni4f', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:49.081244+00', '2026-03-12 09:48:49.513525+00', 'p6vbdwktgvfq', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 957, 'ulpoiitgupuo', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:49.5138+00', '2026-03-12 09:48:49.804747+00', 'ua7tnvq3ni4f', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 958, 'l6eoelkqp553', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:49.805074+00', '2026-03-12 09:48:50.197611+00', 'ulpoiitgupuo', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 959, '47po2lsljsli', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:50.198655+00', '2026-03-12 09:48:50.574343+00', 'l6eoelkqp553', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 960, 'zsnxbjr6sqwd', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:50.574707+00', '2026-03-12 09:48:50.840904+00', '47po2lsljsli', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 961, 'cwi5zze7r3uq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:50.841185+00', '2026-03-12 09:48:51.181205+00', 'zsnxbjr6sqwd', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 962, 'fsj5dytoueje', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:51.182509+00', '2026-03-12 09:48:51.591017+00', 'cwi5zze7r3uq', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 963, 'moyw2svk3tq6', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:51.591991+00', '2026-03-12 09:48:52.024086+00', 'fsj5dytoueje', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 964, 'dw4vh24q67ri', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:52.026382+00', '2026-03-12 09:48:52.269758+00', 'moyw2svk3tq6', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 965, 'wdocfdutbasq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:52.270097+00', '2026-03-12 09:48:52.700765+00', 'dw4vh24q67ri', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 966, 'tj43eacnazot', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:52.701084+00', '2026-03-12 09:48:53.054114+00', 'wdocfdutbasq', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 967, 'wjxyrj4fd4lz', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:53.054624+00', '2026-03-12 09:48:53.821091+00', 'tj43eacnazot', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 968, 'il4rhxlyxsaj', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:53.82175+00', '2026-03-12 09:48:54.14048+00', 'wjxyrj4fd4lz', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 969, 'bgm2mlxxz7rg', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:54.141269+00', '2026-03-12 09:48:54.460943+00', 'il4rhxlyxsaj', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 970, 'glgt4wjvtfs4', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:54.469263+00', '2026-03-12 09:48:54.759668+00', 'bgm2mlxxz7rg', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 971, 'jvu2zwthwspx', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:54.761168+00', '2026-03-12 09:48:55.080121+00', 'glgt4wjvtfs4', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 972, 'cyjc75uit2n4', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:55.080462+00', '2026-03-12 09:48:55.392175+00', 'jvu2zwthwspx', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 973, '2lpqb4us4rjr', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:55.39332+00', '2026-03-12 09:48:55.676521+00', 'cyjc75uit2n4', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 974, 't667uuqeaxn3', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:55.677638+00', '2026-03-12 09:48:56.005355+00', '2lpqb4us4rjr', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 975, 'z4bip35l52pd', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:56.006192+00', '2026-03-12 09:48:56.298639+00', 't667uuqeaxn3', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 976, '3rb5cnelbfmq', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:56.298993+00', '2026-03-12 09:48:56.599466+00', 'z4bip35l52pd', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 977, 'w24lojxvznin', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:56.606748+00', '2026-03-12 09:48:58.855219+00', '3rb5cnelbfmq', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 978, 'ypyndjqtjm5o', '4cb50b66-b09c-4b38-8091-4965a170c788', true, '2026-03-12 09:48:58.855688+00', '2026-03-12 09:48:59.159279+00', 'w24lojxvznin', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 979, 'ojgt35yxubam', '4cb50b66-b09c-4b38-8091-4965a170c788', false, '2026-03-12 09:48:59.160853+00', '2026-03-12 09:48:59.160853+00', 'ypyndjqtjm5o', '9522ca1b-364f-46e3-9a4d-14ef03e2ad1f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 891, 'yq3o5q6bqto2', '781be76f-8857-4aed-842f-d2ac4acfaa27', true, '2026-03-12 03:26:27.688999+00', '2026-03-12 10:18:38.864838+00', 'cwfgmwrcbeqq', '5fe595b7-b160-4372-8c31-87e667096395');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 982, 'tv5sg4gexlyl', '79ea6f3c-4bff-404b-9539-8b64a36a919b', false, '2026-03-12 11:14:06.006994+00', '2026-03-12 11:14:06.006994+00', 'ddxu3hju6xvj', '92e5d6e1-9b1a-4e22-bc23-38878a1957c8');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 986, '6rvpeq3cqg4n', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-12 13:01:03.912441+00', '2026-03-12 13:01:03.912441+00', NULL, '128926ba-9fd5-4024-9884-0bb319152425');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 985, 'xoewntjweznn', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-12 13:01:03.883052+00', '2026-03-12 13:01:03.883052+00', 'jawkvgjuzixe', '0a63e534-77c5-4a42-969d-ddf21f06eee2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 987, '53orukvwqiob', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', false, '2026-03-12 13:52:54.712455+00', '2026-03-12 13:52:54.712455+00', 'gxq47lqkvxm4', '601f8149-3d6f-47b5-b21a-f63706c51de1');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 988, 'zqhq3s5majw3', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', false, '2026-03-12 13:56:34.38711+00', '2026-03-12 13:56:34.38711+00', NULL, 'bc45de2a-3585-4efc-af2a-eee4b4ca183f');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 904, '65dazhwz5hnp', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-12 06:52:14.143641+00', '2026-03-13 15:51:58.718341+00', 'wg7f5k3yepxo', '3fca260f-e54d-4c9f-9a6f-0ba32894f5ea');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 989, 'vn75jl4u4ija', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', false, '2026-03-13 15:51:58.816584+00', '2026-03-13 15:51:58.816584+00', '65dazhwz5hnp', '3fca260f-e54d-4c9f-9a6f-0ba32894f5ea');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 990, 'imcsj7ogj4px', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-13 15:52:15.533584+00', '2026-03-13 16:51:24.584199+00', NULL, 'a3b7762f-88ce-4087-aa59-8a7b0b89d0f2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 992, 'o6r66dzasthi', '71d95693-e5e9-4626-85fc-4a90e261b5b1', false, '2026-03-13 17:00:02.910186+00', '2026-03-13 17:00:02.910186+00', NULL, '82a6d680-b9a7-4b13-a5b0-2ca6095c3cfb');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 993, 'edzwqrcoippt', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', false, '2026-03-13 17:47:57.987949+00', '2026-03-13 17:47:57.987949+00', NULL, '7415b761-99f8-4684-8e3e-6f007f370946');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 991, 'rqrvrfe6kbu3', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', true, '2026-03-13 16:51:24.602129+00', '2026-03-13 17:50:25.372486+00', 'imcsj7ogj4px', 'a3b7762f-88ce-4087-aa59-8a7b0b89d0f2');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 994, 'lec7mgwwdnd6', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', false, '2026-03-13 17:50:25.380195+00', '2026-03-13 17:50:25.380195+00', 'rqrvrfe6kbu3', 'a3b7762f-88ce-4087-aa59-8a7b0b89d0f2');


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.schema_migrations (version) VALUES ('20171026211738');
INSERT INTO auth.schema_migrations (version) VALUES ('20171026211808');
INSERT INTO auth.schema_migrations (version) VALUES ('20171026211834');
INSERT INTO auth.schema_migrations (version) VALUES ('20180103212743');
INSERT INTO auth.schema_migrations (version) VALUES ('20180108183307');
INSERT INTO auth.schema_migrations (version) VALUES ('20180119214651');
INSERT INTO auth.schema_migrations (version) VALUES ('20180125194653');
INSERT INTO auth.schema_migrations (version) VALUES ('00');
INSERT INTO auth.schema_migrations (version) VALUES ('20210710035447');
INSERT INTO auth.schema_migrations (version) VALUES ('20210722035447');
INSERT INTO auth.schema_migrations (version) VALUES ('20210730183235');
INSERT INTO auth.schema_migrations (version) VALUES ('20210909172000');
INSERT INTO auth.schema_migrations (version) VALUES ('20210927181326');
INSERT INTO auth.schema_migrations (version) VALUES ('20211122151130');
INSERT INTO auth.schema_migrations (version) VALUES ('20211124214934');
INSERT INTO auth.schema_migrations (version) VALUES ('20211202183645');
INSERT INTO auth.schema_migrations (version) VALUES ('20220114185221');
INSERT INTO auth.schema_migrations (version) VALUES ('20220114185340');
INSERT INTO auth.schema_migrations (version) VALUES ('20220224000811');
INSERT INTO auth.schema_migrations (version) VALUES ('20220323170000');
INSERT INTO auth.schema_migrations (version) VALUES ('20220429102000');
INSERT INTO auth.schema_migrations (version) VALUES ('20220531120530');
INSERT INTO auth.schema_migrations (version) VALUES ('20220614074223');
INSERT INTO auth.schema_migrations (version) VALUES ('20220811173540');
INSERT INTO auth.schema_migrations (version) VALUES ('20221003041349');
INSERT INTO auth.schema_migrations (version) VALUES ('20221003041400');
INSERT INTO auth.schema_migrations (version) VALUES ('20221011041400');
INSERT INTO auth.schema_migrations (version) VALUES ('20221020193600');
INSERT INTO auth.schema_migrations (version) VALUES ('20221021073300');
INSERT INTO auth.schema_migrations (version) VALUES ('20221021082433');
INSERT INTO auth.schema_migrations (version) VALUES ('20221027105023');
INSERT INTO auth.schema_migrations (version) VALUES ('20221114143122');
INSERT INTO auth.schema_migrations (version) VALUES ('20221114143410');
INSERT INTO auth.schema_migrations (version) VALUES ('20221125140132');
INSERT INTO auth.schema_migrations (version) VALUES ('20221208132122');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195500');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195800');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195900');
INSERT INTO auth.schema_migrations (version) VALUES ('20230116124310');
INSERT INTO auth.schema_migrations (version) VALUES ('20230116124412');
INSERT INTO auth.schema_migrations (version) VALUES ('20230131181311');
INSERT INTO auth.schema_migrations (version) VALUES ('20230322519590');
INSERT INTO auth.schema_migrations (version) VALUES ('20230402418590');
INSERT INTO auth.schema_migrations (version) VALUES ('20230411005111');
INSERT INTO auth.schema_migrations (version) VALUES ('20230508135423');
INSERT INTO auth.schema_migrations (version) VALUES ('20230523124323');
INSERT INTO auth.schema_migrations (version) VALUES ('20230818113222');
INSERT INTO auth.schema_migrations (version) VALUES ('20230914180801');
INSERT INTO auth.schema_migrations (version) VALUES ('20231027141322');
INSERT INTO auth.schema_migrations (version) VALUES ('20231114161723');
INSERT INTO auth.schema_migrations (version) VALUES ('20231117164230');
INSERT INTO auth.schema_migrations (version) VALUES ('20240115144230');
INSERT INTO auth.schema_migrations (version) VALUES ('20240214120130');
INSERT INTO auth.schema_migrations (version) VALUES ('20240306115329');
INSERT INTO auth.schema_migrations (version) VALUES ('20240314092811');
INSERT INTO auth.schema_migrations (version) VALUES ('20240427152123');
INSERT INTO auth.schema_migrations (version) VALUES ('20240612123726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240729123726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240802193726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240806073726');
INSERT INTO auth.schema_migrations (version) VALUES ('20241009103726');
INSERT INTO auth.schema_migrations (version) VALUES ('20250717082212');
INSERT INTO auth.schema_migrations (version) VALUES ('20250731150234');
INSERT INTO auth.schema_migrations (version) VALUES ('20250804100000');
INSERT INTO auth.schema_migrations (version) VALUES ('20250901200500');
INSERT INTO auth.schema_migrations (version) VALUES ('20250903112500');
INSERT INTO auth.schema_migrations (version) VALUES ('20250904133000');
INSERT INTO auth.schema_migrations (version) VALUES ('20250925093508');
INSERT INTO auth.schema_migrations (version) VALUES ('20251007112900');
INSERT INTO auth.schema_migrations (version) VALUES ('20251104100000');
INSERT INTO auth.schema_migrations (version) VALUES ('20251111201300');
INSERT INTO auth.schema_migrations (version) VALUES ('20251201000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260115000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260121000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260219120000');


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('86378985-942c-4d1c-a858-d2adc5a3173f', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '2026-02-28 15:30:32.818884+00', '2026-03-05 12:50:03.197871+00', NULL, 'aal1', NULL, '2026-03-05 12:50:03.197769', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36', '117.102.60.149', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('d479f696-a92e-499f-98ee-3265222309ef', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:49.189098+00', '2026-03-02 16:01:49.189098+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('a5580446-6c88-44fc-9a32-410af5f8a9e5', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:52.010203+00', '2026-03-02 16:01:52.010203+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('b763e30d-92ea-4cce-b2d5-f07142e02ed2', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:55.757102+00', '2026-03-02 16:01:55.757102+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('f773e0de-2a9d-452f-933f-d99dded37e2a', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:58.232248+00', '2026-03-02 16:01:58.232248+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('0e2bcd34-2a6a-4917-af86-4ab5970d2fd2', '7d38a189-b1d5-401e-aba2-36824936da29', '2026-03-01 04:25:28.02805+00', '2026-03-10 08:30:35.046682+00', NULL, 'aal1', NULL, '2026-03-10 08:30:35.043623', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '223.123.106.5', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('10524fe0-e505-4146-b96f-62adfd42ba19', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-02-28 23:37:18.600089+00', '2026-03-02 15:59:52.411065+00', NULL, 'aal1', NULL, '2026-03-02 15:59:52.410965', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('ca867a31-f1d8-4d35-872d-81a72184fca1', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 15:59:52.431608+00', '2026-03-02 15:59:52.431608+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('9d04eada-0910-44d4-bcfa-ab1e7799809c', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:00:46.471258+00', '2026-03-02 16:00:46.471258+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('ef9e7c65-c427-4f40-bca3-e5581e121a83', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:10.507383+00', '2026-03-02 16:01:10.507383+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('b743773b-a449-41af-aebf-b4c16854dce1', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:17.867829+00', '2026-03-02 16:01:17.867829+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('246c555e-ed53-4e87-be1b-26a62c77df86', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:20.652324+00', '2026-03-02 16:01:20.652324+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('2d57e562-1e47-4f19-b795-8c24cf5ef2d8', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:21.742581+00', '2026-03-02 16:01:21.742581+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('3fada469-fba8-4ee9-90fd-dccec49b469f', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:29.376986+00', '2026-03-02 16:01:29.376986+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('cbf7820d-ea74-4aca-8710-f1988ebc6473', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:31.788817+00', '2026-03-02 16:01:31.788817+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('cd274e3e-06ad-4fe3-91a2-5b15f683a044', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:01:40.438781+00', '2026-03-02 16:01:40.438781+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('9dc59fe3-bf49-4d64-bfaa-14ce43475141', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:02:09.533163+00', '2026-03-02 16:02:09.533163+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('79eb8d49-de78-43e4-a269-2e73bd9ba965', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:02:14.931239+00', '2026-03-02 16:02:14.931239+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('a7af0387-ff7b-4722-a62f-9153fbd6ec99', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:02:14.940795+00', '2026-03-02 16:02:14.940795+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36', '37.111.175.247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('03fba9ba-31f8-4cb2-89b7-c496b0e79935', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-02 16:02:17.435248+00', '2026-03-07 02:50:44.339054+00', NULL, 'aal1', NULL, '2026-03-07 02:50:44.33896', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '37.111.182.30', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('c0e3ac74-eb63-4f2b-8d98-1e514d2ed15b', '4cb50b66-b09c-4b38-8091-4965a170c788', '2026-03-11 09:39:11.140669+00', '2026-03-11 09:39:49.81226+00', NULL, 'aal1', NULL, '2026-03-11 09:39:49.812168', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '223.123.114.202', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('fe7d0f79-3be6-4799-9bd8-3f7ebfa94246', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-02-28 15:38:23.573623+00', '2026-03-02 18:38:21.403126+00', NULL, 'aal1', NULL, '2026-03-02 18:38:21.403032', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '117.102.61.12', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('8ab9f851-b08b-4efb-bc95-5250aff059f3', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '2026-03-11 10:14:20.747933+00', '2026-03-11 10:14:20.747933+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '117.102.61.210', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('fd621fa3-5b30-4fe6-bc46-620173a269b2', '5c2531cd-11ef-40f9-9789-10bc77e16808', '2026-03-03 06:03:47.997983+00', '2026-03-12 09:40:18.853468+00', NULL, 'aal1', NULL, '2026-03-12 09:40:18.85055', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '223.123.104.43', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('6c491caf-bbdc-46ec-976d-82e593918525', '5c5a6e76-6682-4405-bad4-32817d63619e', '2026-03-12 03:58:33.238358+00', '2026-03-12 03:58:33.238358+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '223.123.109.204', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('fe70f434-367b-4e36-a64c-fe24b0b8e717', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-03-03 06:15:35.98336+00', '2026-03-03 06:15:35.98336+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '37.111.181.52', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('664cb064-da97-420d-938a-b010e0b84c64', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '2026-03-05 12:50:20.530179+00', '2026-03-07 12:35:57.857176+00', NULL, 'aal1', NULL, '2026-03-07 12:35:57.857076', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36', '117.102.61.146', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('0a63e534-77c5-4a42-969d-ddf21f06eee2', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-03-10 09:55:22.297557+00', '2026-03-12 13:01:03.995371+00', NULL, 'aal1', NULL, '2026-03-12 13:01:03.989571', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', '117.102.62.199', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('812df86d-8f84-4c27-b728-a148075555ca', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', '2026-03-02 10:15:29.155223+00', '2026-03-11 17:49:25.667433+00', NULL, 'aal1', NULL, '2026-03-11 17:49:25.666203', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '119.155.206.78', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('f403d187-b910-495a-a3a6-46678bd444dd', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '2026-03-12 02:12:51.41937+00', '2026-03-12 09:34:23.663966+00', NULL, 'aal1', NULL, '2026-03-12 09:34:23.657261', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', '37.111.156.19', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('348223b8-a885-4548-b609-0811ce2224bd', '805ab41a-0b79-4e31-b0d2-072a072a443b', '2026-03-11 10:13:42.171013+00', '2026-03-12 04:16:55.725004+00', NULL, 'aal1', NULL, '2026-03-12 04:16:55.724904', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '117.102.63.90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('27cbf38c-9108-4eb4-a081-16d6f7982021', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '2026-02-28 15:32:01.815549+00', '2026-03-12 09:37:22.46235+00', NULL, 'aal1', NULL, '2026-03-12 09:37:22.462207', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36', '223.123.108.125', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('75f843a2-1284-4801-bb5f-7f275d4dd457', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '2026-03-12 09:34:30.047389+00', '2026-03-12 09:34:30.047389+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', '37.111.156.19', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('51edfdb8-a720-4ace-b01e-745773828af6', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '2026-03-11 10:15:10.105722+00', '2026-03-12 11:59:27.006701+00', NULL, 'aal1', NULL, '2026-03-12 11:59:27.006603', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', '223.123.111.166', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('7b5e59c3-47a7-4e09-8723-01005e95ece4', '781be76f-8857-4aed-842f-d2ac4acfaa27', '2026-03-01 12:34:17.660101+00', '2026-03-04 10:01:59.318609+00', NULL, 'aal1', NULL, '2026-03-04 10:01:59.318516', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', '37.111.159.217', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('d49eb474-ca18-4fd7-a1d8-db8ce73c69c4', '08c23b1e-112e-4291-9c0b-551f16632f05', '2026-03-05 10:16:28.164646+00', '2026-03-05 15:32:58.26926+00', NULL, 'aal1', NULL, '2026-03-05 15:32:58.269162', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '37.111.159.23', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('98378a67-f2e0-4698-9fc6-ed86603c3d2a', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', '2026-03-10 07:56:34.310132+00', '2026-03-12 06:02:01.437674+00', NULL, 'aal1', NULL, '2026-03-12 06:02:01.437563', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '182.178.100.162', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('ca021e11-f82d-46df-b68d-6d7ec803b7e7', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '2026-03-11 09:39:17.828181+00', '2026-03-11 10:38:22.621607+00', NULL, 'aal1', NULL, '2026-03-11 10:38:22.621497', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.61.210', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('bc45de2a-3585-4efc-af2a-eee4b4ca183f', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '2026-03-12 13:56:33.320607+00', '2026-03-12 13:56:33.320607+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '39.50.182.145', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('e07d8672-d6c7-4f89-b493-d69af60bb784', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '2026-03-12 02:18:14.019959+00', '2026-03-12 02:18:14.019959+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '37.111.174.181', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('acaa1c68-5539-4f14-b89e-7c6dc6aa0bf1', '08c23b1e-112e-4291-9c0b-551f16632f05', '2026-03-06 09:24:34.647846+00', '2026-03-06 09:24:34.647846+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.60.132', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('666ddd72-dc90-4603-a516-6ee6f09a558f', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', '2026-03-06 16:28:47.854958+00', '2026-03-11 09:08:43.198965+00', NULL, 'aal1', NULL, '2026-03-11 09:08:43.198052', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '223.123.106.45', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('3fca260f-e54d-4c9f-9a6f-0ba32894f5ea', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '2026-03-11 16:28:04.307092+00', '2026-03-13 15:51:59.041636+00', NULL, 'aal1', NULL, '2026-03-13 15:51:59.038386', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.61.83', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('a9cb4a50-76dd-4ffa-9598-272834953588', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '2026-03-07 02:50:53.805397+00', '2026-03-12 08:45:05.643715+00', NULL, 'aal1', NULL, '2026-03-12 08:45:05.642724', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '37.111.139.100', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('82a6d680-b9a7-4b13-a5b0-2ca6095c3cfb', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-03-13 17:00:02.884346+00', '2026-03-13 17:00:02.884346+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', '37.111.175.133', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('8de9e949-9b8c-4bf0-8085-a16d19877804', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', '2026-03-06 09:38:55.5156+00', '2026-03-06 16:28:43.476768+00', NULL, 'aal1', NULL, '2026-03-06 16:28:43.476625', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '223.123.111.36', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('d3bef874-b76a-46f9-9524-a3539551e1f8', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '2026-03-11 10:36:13.605326+00', '2026-03-12 09:26:56.587494+00', NULL, 'aal1', NULL, '2026-03-12 09:26:56.586978', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '37.111.181.144', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('dd68870e-5987-4151-97ad-64ae16665c01', '805ab41a-0b79-4e31-b0d2-072a072a443b', '2026-03-12 09:39:48.159334+00', '2026-03-12 09:39:48.159334+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '117.102.63.90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('6fb0429d-40a1-48cc-a107-a5c218ee99b5', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', '2026-03-05 04:18:26.625805+00', '2026-03-06 09:38:36.063909+00', NULL, 'aal1', NULL, '2026-03-06 09:38:36.063813', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '223.123.111.30', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('90dc03e3-ae2a-496c-b468-2c033578e6e8', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-03-04 10:10:11.813896+00', '2026-03-05 05:43:46.823097+00', NULL, 'aal1', NULL, '2026-03-05 05:43:46.822993', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', '37.111.174.223', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('9522ca1b-364f-46e3-9a4d-14ef03e2ad1f', '4cb50b66-b09c-4b38-8091-4965a170c788', '2026-03-12 09:48:05.177253+00', '2026-03-12 09:48:59.163374+00', NULL, 'aal1', NULL, '2026-03-12 09:48:59.163274', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.63.90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('92e5d6e1-9b1a-4e22-bc23-38878a1957c8', '79ea6f3c-4bff-404b-9539-8b64a36a919b', '2026-03-04 09:41:43.58639+00', '2026-03-12 11:14:06.028883+00', NULL, 'aal1', NULL, '2026-03-12 11:14:06.028785', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '117.102.63.90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('d916e10d-7753-483e-9136-ed122851652f', '5c2531cd-11ef-40f9-9789-10bc77e16808', '2026-03-05 09:22:59.147577+00', '2026-03-05 09:22:59.147577+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '223.123.105.215', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('6d37d23d-7706-47d7-a509-5586f95160b8', '5c2531cd-11ef-40f9-9789-10bc77e16808', '2026-03-05 10:03:24.59046+00', '2026-03-05 10:03:24.59046+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '223.123.111.25', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('af4c298a-288a-460a-b53a-f2d46008f86a', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '2026-03-07 17:26:31.202437+00', '2026-03-07 17:26:31.202437+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36', '117.102.61.146', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('4faa9291-e18c-4de9-905c-2808c78bb264', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '2026-03-07 12:36:18.703877+00', '2026-03-08 06:40:48.704248+00', NULL, 'aal1', NULL, '2026-03-08 06:40:48.704139', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36', '117.102.61.146', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('ff2cd62f-f762-403d-b73d-048f6af1fdb8', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', '2026-03-06 09:28:59.541065+00', '2026-03-09 09:15:14.546006+00', NULL, 'aal1', NULL, '2026-03-09 09:15:14.545913', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.60.154', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('d55783f9-a875-454b-97cd-e3957b966821', '08a46873-b1cf-4b3e-92b2-37e662a11775', '2026-03-07 18:01:41.953643+00', '2026-03-07 18:01:41.953643+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', '103.12.121.186', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('2df65f47-ebf2-489f-8ccc-a482e6972efe', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-03-05 05:43:46.83053+00', '2026-03-08 10:11:43.450631+00', NULL, 'aal1', NULL, '2026-03-08 10:11:43.450537', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', '117.102.63.34', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('8e45b52c-3ca9-449c-a6bd-00d5dfaaf1c4', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', '2026-03-08 14:32:39.556364+00', '2026-03-12 08:08:15.284668+00', NULL, 'aal1', NULL, '2026-03-12 08:08:15.284285', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0', '117.102.61.90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('a20bb4ea-e677-4a3f-bd10-4fd3f57a4648', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', '2026-03-12 02:53:58.399653+00', '2026-03-12 08:36:44.93392+00', NULL, 'aal1', NULL, '2026-03-12 08:36:44.931878', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', '37.111.129.200', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('7415b761-99f8-4684-8e3e-6f007f370946', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '2026-03-13 17:47:57.965657+00', '2026-03-13 17:47:57.965657+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36', '103.200.198.58', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('a3b7762f-88ce-4087-aa59-8a7b0b89d0f2', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '2026-03-13 15:52:15.472874+00', '2026-03-13 17:50:25.387927+00', NULL, 'aal1', NULL, '2026-03-13 17:50:25.387412', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.61.83', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('0004f6b4-6d70-408c-9371-6744d219688d', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '2026-03-11 21:17:21.298977+00', '2026-03-11 21:17:21.298977+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '117.102.55.68', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('d96f5a0c-5e88-4e0e-a4b7-884191afe5ed', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-03-08 10:12:42.015096+00', '2026-03-10 08:49:58.054123+00', NULL, 'aal1', NULL, '2026-03-10 08:49:58.054025', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', '117.102.60.221', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('0ffbeb63-c37f-4ca8-8056-0a8cb6ed2641', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '2026-03-10 15:40:34.98049+00', '2026-03-12 02:18:15.138958+00', NULL, 'aal1', NULL, '2026-03-12 02:18:15.093479', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Mobile Safari/537.36', '37.111.174.181', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('597bf3e7-3932-4548-a4c7-f11fdaee2a0c', '4cb50b66-b09c-4b38-8091-4965a170c788', '2026-03-12 09:47:00.014752+00', '2026-03-12 09:47:12.759786+00', NULL, 'aal1', NULL, '2026-03-12 09:47:12.735893', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.63.90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('3d9df9a2-2d8c-4a10-bd4f-c198a8a40b2d', '4cb50b66-b09c-4b38-8091-4965a170c788', '2026-03-12 09:53:03.358161+00', '2026-03-12 09:53:03.358161+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '117.102.63.90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('5fe595b7-b160-4372-8c31-87e667096395', '781be76f-8857-4aed-842f-d2ac4acfaa27', '2026-03-04 10:03:03.350878+00', '2026-03-12 10:18:38.919551+00', NULL, 'aal1', NULL, '2026-03-12 10:18:38.918766', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', '223.123.106.159', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('128926ba-9fd5-4024-9884-0bb319152425', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '2026-03-12 13:01:03.784723+00', '2026-03-12 13:01:03.784723+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', '117.102.62.199', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('601f8149-3d6f-47b5-b21a-f63706c51de1', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '2026-03-08 06:40:49.438819+00', '2026-03-12 13:52:54.754514+00', NULL, 'aal1', NULL, '2026-03-12 13:52:54.753294', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36', '117.102.63.144', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('32a73cb8-db9d-440d-be68-464ffc13c02a', '08a46873-b1cf-4b3e-92b2-37e662a11775', '2026-03-08 07:33:53.713805+00', '2026-03-11 07:51:49.041902+00', NULL, 'aal1', NULL, '2026-03-11 07:51:49.04178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', '103.12.121.224', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('eff59d0d-1e66-43ad-aa43-7a3639b7a649', 'c551abc6-369e-4722-8a1f-f442501db0a2', '2026-03-11 08:15:55.741808+00', '2026-03-11 08:15:55.741808+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Linux; U; Android 12; zh-cn; TECNO BF7 Build/SP1A.210812.016) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/103.0.5060.129 HiBrowser/v2.10.1.2 UWS/ Mobile Safari/537.36', '37.111.149.234', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', 'authenticated', 'authenticated', 'tushalparwani@gmail.com', '$2a$10$NV0aFEoij1V.TZI8eFe/KuC5XKlc1hrqt5wgNEvn4eBdHJ4AxWKpS', '2026-02-28 04:40:09.943457+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-13 17:47:57.965565+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "c6769364-3029-4cb3-8b72-ba24c7c5ee5a", "name": "Tushal Kumar", "email": "tushalparwani@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 04:40:09.901101+00', '2026-03-13 17:47:58.008956+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'authenticated', 'authenticated', 'mkuk2013@gmail.com', '$2a$10$75iDm5CnfhnKOBShwXqJe.kDfrBbsgeX7LnzAc2.XiE5kJf9s1Dcm', '2026-02-27 13:13:32.338884+00', NULL, '', NULL, '', '2026-03-11 10:13:25.918624+00', '', '', NULL, '2026-03-13 15:52:15.472744+00', '{"provider": "email", "providers": []}', '{"role": "admin"}', NULL, '2026-02-27 13:13:32.338884+00', '2026-03-13 17:50:25.383494+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'authenticated', 'authenticated', 'demostudent@gmail.com', '$2a$10$TXwzPWKH0aafGGQofiu7JeS61MQOGbp8Su//AQ0bTuALcgc5z6yCm', '2026-02-27 16:08:39.928227+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-09 18:46:33.963924+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "adfe2a8c-2570-4c32-95b2-f70540048848", "name": "Demo Student", "email": "demostudent@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-27 16:08:39.907731+00', '2026-03-09 18:46:34.008415+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '781be76f-8857-4aed-842f-d2ac4acfaa27', 'authenticated', 'authenticated', 'dils40732@gmail.com', '$2a$10$PfGd8TM6kV2cW6pNUeh2KuIYD5xfK4AbdXkUAUv4.C/f68OUYPr5q', '2026-02-28 04:48:47.161839+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-04 10:03:03.350324+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "781be76f-8857-4aed-842f-d2ac4acfaa27", "name": "Dilsher ", "email": "dils40732@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 04:48:47.132122+00', '2026-03-12 10:18:38.908831+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', 'authenticated', 'authenticated', 'muhammadsiddiquerahimoon711@gmail.com', '$2a$10$5lBvyDo5546mfSQjPKCPa.ZE0rfehvhTOjHjTwYRqOuKbx43Ndmri', '2026-02-28 14:50:37.504035+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-08 06:40:49.438715+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "26143df4-85ca-4a53-a7d9-ea6560e29bf6", "name": "Muhammad Siddique Rahimon ", "email": "muhammadsiddiquerahimoon711@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 14:50:37.456102+00', '2026-03-12 13:52:54.732928+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'b1c43bc7-dee8-4257-8b15-374c11a9c2ed', 'authenticated', 'authenticated', 'parkashjai124@gmail.com', '$2a$10$uBtW4LC15NuYdworE9FcAONO9iPpksaanNtVDTdN7IT.PFNe6xpZ.', '2026-02-28 06:14:39.037932+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-02-28 09:58:42.569713+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "b1c43bc7-dee8-4257-8b15-374c11a9c2ed", "name": "Om Pirkas", "email": "parkashjai124@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 06:14:38.960862+00', '2026-02-28 09:58:42.57813+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '7ba9b0e1-bcdd-4d44-91e9-8f4043ae415b', 'authenticated', 'authenticated', 'dolatrai018@gmail.com', '$2a$10$DwKdMwJmCEqLD3azZOwBOO00LTWPUjj4ub8fveig3AYIECLJnUEle', '2026-02-28 12:59:41.665446+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-02-28 12:59:57.756584+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "7ba9b0e1-bcdd-4d44-91e9-8f4043ae415b", "name": "Dolat Rai ", "email": "dolatrai018@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 12:59:41.602311+00', '2026-02-28 12:59:57.7928+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '805ab41a-0b79-4e31-b0d2-072a072a443b', 'authenticated', 'authenticated', 'chandarkumarmalhi502@gmail.com', '$2a$10$1KNSLCL0zhVNmtDyRbXE6ueyAzxbJ6gBiGNMyGtgAeNgu7w6cSVwq', '2026-02-28 04:42:51.027417+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-12 09:39:48.158351+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "805ab41a-0b79-4e31-b0d2-072a072a443b", "name": "Chandar Kumar ", "email": "chandarkumarmalhi502@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 04:42:50.954746+00', '2026-03-12 09:39:48.227082+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '717b9547-5aaa-4947-9a03-5dc6d419f68c', 'authenticated', 'authenticated', 'rathoremehandersingh@gmail.com', '$2a$06$cZY9lHZGiiK5eBbehOYv0uC.4JizcJyJfN8s.RPxis/1j81/1rGgi', '2026-02-28 07:32:45.985185+00', NULL, '', NULL, '', '2026-03-11 15:38:30.851954+00', '', '', NULL, '2026-03-12 12:45:40.443342+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "717b9547-5aaa-4947-9a03-5dc6d419f68c", "name": "Mehander Singh", "email": "rathoremehandersingh@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 07:32:45.925673+00', '2026-03-12 12:45:40.514748+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', 'authenticated', 'authenticated', 'saroopalam@gmail.com', '$2a$10$0l.URrbLhR2BbnFaxyV58eWTdwR4grls59ccL/eKLwaNrUsO2xQI2', '2026-02-28 15:11:31.991255+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-12 02:53:58.391327+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "97af47f1-a0f4-423a-8f22-9a8d8a48588f", "name": "Saroop chand ", "email": "saroopalam@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 15:11:31.897854+00', '2026-03-12 08:36:44.848796+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', 'authenticated', 'authenticated', 'shahnwazsamejo786@gmail.com', '$2a$10$QEz5ZWem8U5JAZ9j1ZO6FuNEDyELNgKhMeY5k3KlxnaBi3g5z2aDm', '2026-02-28 04:45:35.460372+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-06 09:28:59.540967+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "b23c4b2f-c6a9-470e-bb04-b55f96391760", "name": "Shahnawaz ", "email": "shahnwazsamejo786@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 04:45:35.419477+00', '2026-03-11 17:49:25.656764+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '66dc3746-cc17-4afc-b67b-17a4eda74e12', 'authenticated', 'authenticated', 'salamrahikunbher@gmail.com', '$2a$10$6cuG7bP4XYRCQTtqmdtwx.2Qsz6kyWlQeGUz4LH7L4kpkJemyFUg2', '2026-02-28 14:46:36.149799+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-10 15:40:34.980373+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "66dc3746-cc17-4afc-b67b-17a4eda74e12", "name": "Abdulsalam kunbher ", "email": "salamrahikunbher@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 14:46:36.102277+00', '2026-03-12 02:18:14.818703+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '71d95693-e5e9-4626-85fc-4a90e261b5b1', 'authenticated', 'authenticated', 'lajpatraibheel545@gmail.com', '$2a$10$PeyvZPbCCSj9BEGC9SWziuwSUYTmCEYd7DuhOHKkCwrw57ExcsYhS', '2026-02-28 14:29:43.402034+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-13 17:00:02.884248+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "71d95693-e5e9-4626-85fc-4a90e261b5b1", "name": "Lajpat ", "email": "lajpatraibheel545@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 14:29:43.345245+00', '2026-03-13 17:00:02.926579+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '5c5a6e76-6682-4405-bad4-32817d63619e', 'authenticated', 'authenticated', 'rehmanali2k22@gmail.com', '$2a$10$ZHtVj8atncuQbG2uFUHjeePfOFdeMzA5/oLsCynGJ1tEIimi2eGH2', '2026-03-04 09:45:47.164074+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-12 03:58:33.236168+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "5c5a6e76-6682-4405-bad4-32817d63619e", "name": "Rehman ali", "email": "rehmanali2k22@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-04 09:45:47.092309+00', '2026-03-12 03:58:33.317575+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'e5540156-8936-4a5c-ab78-4f1b503649f0', 'authenticated', 'authenticated', 'ompirkashbheel417@gmail.com', '$2a$06$ATfGNpMnft8SmGJU9BNzAuUvegkyX.gfiSVJm4TXqkJgLVDqJY6He', '2026-03-01 04:34:32.268404+00', NULL, '', NULL, '0b865c6b64f2f95edbb40a69feb22069f81addc7b0873510b5785e8e', '2026-03-11 09:04:17.554511+00', '', '', NULL, '2026-03-11 10:36:13.599555+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "e5540156-8936-4a5c-ab78-4f1b503649f0", "name": "Ompirkash Bheel", "email": "ompirkashbheel417@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-01 04:34:32.213371+00', '2026-03-12 09:26:56.5772+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '4cb50b66-b09c-4b38-8091-4965a170c788', 'authenticated', 'authenticated', 'alihassanbajeer555@gmail.com', '$2a$10$0ESnPSonzlNqLnx6AlI5qOSDwjSlHumrBE.5vrG2PD8vzUvbmD82W', '2026-03-05 10:14:56.586739+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-12 09:53:03.355445+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "4cb50b66-b09c-4b38-8091-4965a170c788", "name": "Ali Hassan Bajeer", "email": "alihassanbajeer555@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-05 10:14:56.516213+00', '2026-03-12 09:53:03.763223+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '5c2531cd-11ef-40f9-9789-10bc77e16808', 'authenticated', 'authenticated', 'alikkrizwan01@gmail.com', '$2a$10$A1H6.um/jAZEbWj0mSOJl.87HN0OJV8si/ssypYe6eLBaIPLEdQzy', '2026-03-02 12:15:06.455974+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-05 10:03:24.590328+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "5c2531cd-11ef-40f9-9789-10bc77e16808", "name": "Rizwan Ali", "email": "alikkrizwan01@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-02 12:15:06.388744+00', '2026-03-12 09:40:18.8246+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '7d38a189-b1d5-401e-aba2-36824936da29', 'authenticated', 'authenticated', 'samejomuneerraza@gmail.com', '$2a$10$NfSz4sH7mzEOn8XD/u8A4OZR3/45cQ16dsogmYVMxkhQATTJr80Mm', '2026-03-01 04:12:45.033057+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-01 04:25:28.027959+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "7d38a189-b1d5-401e-aba2-36824936da29", "name": "MuneerRaza Samejo", "email": "samejomuneerraza@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-01 04:12:44.953071+00', '2026-03-10 08:30:35.026462+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '79ea6f3c-4bff-404b-9539-8b64a36a919b', 'authenticated', 'authenticated', 'ranausama000009@gmail.com', '$2a$10$9I9FRsxbZgII64WoiVDRHeXx75nmcJ9kXZh65rEdV4KYDpiM2Mq6W', '2026-03-04 09:40:56.228169+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-04 09:41:43.586285+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "79ea6f3c-4bff-404b-9539-8b64a36a919b", "name": "Usama ", "email": "ranausama000009@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-04 09:40:56.150573+00', '2026-03-12 11:14:06.021112+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '08c23b1e-112e-4291-9c0b-551f16632f05', 'authenticated', 'authenticated', 'hidayatallahsamejo2@gmail.com', '$2a$06$tBcpb4qAgRI21DTIz5sJS.Avg5y/V4E2RH//w39j7qIapyQ3CZ/BG', '2026-02-28 15:31:51.638274+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-06 09:24:34.6477+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "08c23b1e-112e-4291-9c0b-551f16632f05", "name": "Hidayatallah ", "email": "hidayatallahsamejo2@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 15:31:51.602656+00', '2026-03-06 09:24:34.733112+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', 'authenticated', 'authenticated', 'malangnk67@gmail.com', '$2a$10$YI9JEskQk4H42FmRyNrSTe.Bkef..mETMXONSBwqA5H2ZVZqlXzxm', '2026-03-01 09:08:05.931384+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-12 13:56:33.280484+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "94b1710e-1c51-4f1b-87a0-fceaffaebd73", "name": "Narender Kumar ", "email": "malangnk67@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-01 09:08:05.865316+00', '2026-03-12 13:56:35.02096+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', 'authenticated', 'authenticated', 'papuradhani342@gmail.com', '$2a$06$2.eFd27rrvXKaYYxmZnZVeYqFApiWJrE8W1eKilG/jyGzk2suQ2oW', '2026-03-02 09:51:49.816207+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-06 16:28:47.854874+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6", "name": "Papu", "email": "papuradhani342@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-02 09:51:49.721906+00', '2026-03-11 09:08:43.188671+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '494e18ab-b18b-4f7d-b33a-83ac7d3d480f', 'authenticated', 'authenticated', 'vehroroadsammamohlla@gmail.com', '$2a$10$s/N/gDcLRD73q9N6KSfWz.jQPeluCH8IMZCqEGQjwqzaF/KMHdyOy', '2026-03-06 08:27:22.983958+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-06 08:27:29.125631+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "494e18ab-b18b-4f7d-b33a-83ac7d3d480f", "name": "Munawar hussain", "email": "vehroroadsammamohlla@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-06 08:27:22.919926+00', '2026-03-06 08:27:29.128807+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'c551abc6-369e-4722-8a1f-f442501db0a2', 'authenticated', 'authenticated', '469mrmb@gmail.com', '$2a$06$swY9dNwZ9yt.MuW53QHn7u97dGmA2peUSbb2oyLdqmGf/poW6WDZi', '2026-03-04 09:28:45.856879+00', NULL, '', NULL, 'a740ec3a1c64948936ef69ecdb4ece51a623c6fe5eef067a39564275', '2026-03-11 06:52:25.787437+00', '', '', NULL, '2026-03-11 08:15:55.741293+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "c551abc6-369e-4722-8a1f-f442501db0a2", "name": "Moti Ram", "email": "469mrmb@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-04 09:28:45.79507+00', '2026-03-11 08:15:55.791695+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', 'authenticated', 'authenticated', 'muhammadkhannohari720@gmail.com', '$2a$10$l6I3jJXvhrvDTW9oQ2mjm.w5Z5qTDnd3GynNexE4g2R3oeCRVAHGK', '2026-02-28 15:37:26.441214+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-07 02:50:53.805311+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "05dafca0-fdd7-4acc-bba5-ec4ee9aca6be", "name": "Muhammad Khan Nohari", "email": "muhammadkhannohari720@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-02-28 15:37:26.395688+00', '2026-03-12 08:45:05.629075+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '08a46873-b1cf-4b3e-92b2-37e662a11775', 'authenticated', 'authenticated', 'hidayat.wali3600@gmail.com', '$2a$10$JIc8sbvUQ3jEG7UMPiFXLeUJD6WE10.ZDPCtiEGeoTEhpn.xbl6BC', '2026-03-06 15:16:12.725088+00', NULL, '', NULL, 'ea633a19de8cf2fa51ee460fe169f5392171db187bbabd6855639f12', '2026-03-06 15:30:12.343504+00', '', '', NULL, '2026-03-08 07:33:53.713711+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "08a46873-b1cf-4b3e-92b2-37e662a11775", "name": "Hidayatullah", "email": "hidayat.wali3600@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-06 15:16:12.66277+00', '2026-03-11 07:51:49.033649+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '025e3598-2401-4955-91c8-e8d9c32542fb', 'authenticated', 'authenticated', 'mkuk2015@gmail.com', '$2a$10$gC9fX/u7qzRQwigGHJBpLOv5fyvarQH7BLYlyYd/6xxKAeaD4lNbK', '2026-03-07 17:27:23.140684+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-09 17:47:43.271721+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "025e3598-2401-4955-91c8-e8d9c32542fb", "name": "Mukesh Kumar", "email": "mkuk2015@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-07 17:27:23.043771+00', '2026-03-09 17:47:43.3059+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', 'authenticated', 'authenticated', 'kumarpartab109@gmail.com', '$2a$10$NsrMSdGmj6zDP3753FnhDuX7IKVdn8u7GPO4cG4R389cTMLOnGSr.', '2026-03-10 02:34:29.203666+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-10 07:56:34.309593+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac", "name": "Partab ", "email": "kumarpartab109@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-10 02:34:29.128387+00', '2026-03-12 06:02:01.429776+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', 'authenticated', 'authenticated', 'anandkumarmalhi440@gmail.com', '$2a$10$JG5cN3ZQqjIVVzr0WGZ5Q.QVZzyHVqDQnqN.QKDG7oXcMaFhhkKFC', '2026-03-08 11:50:05.460823+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-03-08 14:32:39.555857+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "38dfd37b-123f-4938-93b3-dca1dfbb4b08", "name": "Anand kumar", "email": "anandkumarmalhi440@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-03-08 11:50:05.40062+00', '2026-03-12 08:08:15.276626+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: admin_chat_messages; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('4adf0694-fb57-415a-aea9-f8f8cc510dee', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Hello', false, '2026-03-09 16:37:02.161293+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('0240e05e-a924-433e-ba8e-f3cb9919c33d', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Hello', false, '2026-03-09 16:38:01.6567+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('3fd92b70-e6f3-499c-9a6d-7e58d992de85', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'hi', false, '2026-03-09 16:46:23.15576+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('d79ff2cb-672a-4292-bb6c-7363f9cd1722', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Hi', false, '2026-03-09 16:46:31.320486+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('97c3b5b4-efbb-4107-8e7d-db32fb32de28', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Hello', false, '2026-03-09 16:47:00.914618+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('403af420-7ace-4a77-b5b4-c761399dd0ea', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'HI', false, '2026-03-09 16:47:27.503856+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('6cd16e12-1fff-4970-86d8-7890b26dbec7', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'hi', false, '2026-03-09 16:50:44.771558+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('ed951f19-2bfb-4e9d-bdf3-7eca4ddc10d3', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Hi', false, '2026-03-09 16:56:56.744943+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('d04ccd6f-d8f3-4aed-8ad5-80004ef4c795', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'Hi', false, '2026-03-09 16:57:38.885691+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('74a2fca5-96e8-4d88-9d80-03958a6057cc', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Hi', false, '2026-03-09 17:08:38.262458+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('2b1c123c-9ff6-4be5-ab54-664278d5b656', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'HI', false, '2026-03-09 17:10:00.061398+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('c7bb7608-0d99-4e71-a04f-8809933012e3', '025e3598-2401-4955-91c8-e8d9c32542fb', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Hi', false, '2026-03-09 17:47:51.190049+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('1e1c58c7-0098-455e-8a18-a98d75100616', '025e3598-2401-4955-91c8-e8d9c32542fb', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'I found a bug/system issue.', false, '2026-03-09 18:05:40.916514+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('ceddb2c8-b2f8-4694-8871-9891e3b05455', '025e3598-2401-4955-91c8-e8d9c32542fb', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'I need help with a task.', false, '2026-03-09 18:05:45.535129+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('5e1457ae-f342-48bd-8021-9b1dad2faefd', '025e3598-2401-4955-91c8-e8d9c32542fb', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Can you check my submission?', false, '2026-03-09 18:05:47.586278+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('36845494-94ca-4550-86a2-daecb621698c', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '025e3598-2401-4955-91c8-e8d9c32542fb', 'Ok', false, '2026-03-09 18:28:44.048793+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('54a70843-ac73-48a6-9745-6d484727c76c', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'hi', false, '2026-03-09 18:58:25.642231+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('aa8996b9-ef52-4ecf-91f0-85fc62c5f231', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'Hi', false, '2026-03-09 18:59:11.300004+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('7ee17454-5213-4347-99b1-d99ac0de4c70', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'I found a bug/system issue.', false, '2026-03-10 08:05:11.704802+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('d7da56db-78c9-43d2-9ce9-e3bc65a22dbf', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Can you check my submission?', false, '2026-03-10 08:05:12.142968+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('8914c017-fbda-42b0-a962-307872d47bd0', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'I need help with a task.', false, '2026-03-10 08:05:19.029318+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('437b480d-16e5-4de1-8d6d-0fc0a405fed3', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'I need help with a task.', false, '2026-03-10 08:05:20.603688+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('4165596b-bcfb-4c29-b55f-d31745c2a172', '71d95693-e5e9-4626-85fc-4a90e261b5b1', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Sir code pr click karne se picture show nahe ho rehaye hai', false, '2026-03-10 14:53:43.836994+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('5e632f30-5d55-404a-91f9-e7b7a30dacc7', '71d95693-e5e9-4626-85fc-4a90e261b5b1', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Compress bhe kr dea', false, '2026-03-10 14:54:08.190271+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('b9e3faa6-e4a2-4a27-8d82-641b07b5f795', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'sir task check kree', false, '2026-03-10 16:21:39.658081+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('fe7d0f37-df7a-4ff4-a085-dd97b2ff6a82', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'net kesee or ka connect hmm', false, '2026-03-10 16:22:07.242138+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('9d61f58a-56eb-49eb-8105-66c66d8f0faf', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', 'ok which help', false, '2026-03-11 16:43:45.808258+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('4345b943-33de-4c62-b3bd-c711a09e569f', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', '71d95693-e5e9-4626-85fc-4a90e261b5b1', 'phr se try karo or again upload kro', false, '2026-03-11 16:44:03.1628+00');
INSERT INTO public.admin_chat_messages (id, sender_id, receiver_id, content, is_read, created_at) VALUES ('5380d87e-b056-4754-9a94-00f61b900fea', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'I need help with a task.', false, '2026-03-12 03:18:15.311459+00');


--
-- Data for Name: arcade_config; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.arcade_config (id, is_unlocked, updated_at) VALUES (1, true, '2026-02-27 13:37:41.739135+00');


--
-- Data for Name: exam_results; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: exam_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.exam_settings (id, is_active, exam_title, duration_minutes, updated_at) VALUES (1, false, 'Final Assessment', 60, '2026-02-27 13:37:41.739135+00');


--
-- Data for Name: feedback; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: game_scores; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: notices; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: personal_storage; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.personal_storage (id, user_id, name, url, size, type, created_at) VALUES ('df23e4dd-3b01-4021-b7b0-99d3c26c4203', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'Teacher.jpeg', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1772288697/personal_storage/adfe2a8c-2570-4c32-95b2-f70540048848/Teacher_id_card_design_realistic_f4eec21ca8_1772288694853.jpg', 710993, 'image/jpeg', '2026-02-28 14:24:57.572+00');
INSERT INTO public.personal_storage (id, user_id, name, url, size, type, created_at) VALUES ('f7cefcd4-5dd9-4aa1-870e-384b61349e61', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'NAVTTC_WEB_DEVELOPMENT_rkzrva.zip', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1772462057/personal_storage/adfe2a8c-2570-4c32-95b2-f70540048848/NAVTTC_WEB_DEVELOPMENT_rkzrva_yiguom.zip', 2502, 'application/x-zip-compressed', '2026-03-02 14:34:16.628+00');
INSERT INTO public.personal_storage (id, user_id, name, url, size, type, created_at) VALUES ('94c5a5e1-e360-47bb-a986-9def9abf7afc', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'Traffic-Light_vwqcyi.zip', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1772462434/personal_storage/adfe2a8c-2570-4c32-95b2-f70540048848/Traffic-Light_vwqcyi_1772462432140.zip', 953, 'application/x-zip-compressed', '2026-03-02 14:40:34.118+00');
INSERT INTO public.personal_storage (id, user_id, name, url, size, type, created_at) VALUES ('1d887e4d-0b5f-45de-9207-bbe1f5def388', '71d95693-e5e9-4626-85fc-4a90e261b5b1', 'Gemini_Generated_Image_wddcr0wddcr0wddc.png', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1772468274/personal_storage/71d95693-e5e9-4626-85fc-4a90e261b5b1/Gemini_Generated_Image_wddcr0wddcr0wddc_1772468255564.png', 1524805, 'image/png', '2026-03-02 16:17:54.054+00');


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('5c5a6e76-6682-4405-bad4-32817d63619e', '5c5a6e76-6682-4405-bad4-32817d63619e', 'Rehman ali', 'rehmanali2k22@gmail.com', 'student', NULL, 'approved', '2026-03-04 09:45:47.089333+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('a01b174b-4c80-4fc7-a47d-db292f995fe3', 'a01b174b-4c80-4fc7-a47d-db292f995fe3', 'Mukesh Kumar', 'mkuk2013@gmail.com', 'admin', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1772200757/avatar_a0sthw.png', 'active', '2026-02-27 13:13:32.338884+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('adfe2a8c-2570-4c32-95b2-f70540048848', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'Demo Student', 'demostudent@gmail.com', 'student', NULL, 'approved', '2026-02-27 16:08:41.421721+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('4cb50b66-b09c-4b38-8091-4965a170c788', '4cb50b66-b09c-4b38-8091-4965a170c788', 'Ali Hassan Bajeer', 'alihassanbajeer555@gmail.com', 'student', NULL, 'approved', '2026-03-05 10:14:56.514635+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('c6769364-3029-4cb3-8b72-ba24c7c5ee5a', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', 'Tushal Kumar', 'tushalparwani@gmail.com', 'student', NULL, 'approved', '2026-02-28 04:40:09.900292+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('805ab41a-0b79-4e31-b0d2-072a072a443b', '805ab41a-0b79-4e31-b0d2-072a072a443b', 'Chandar Kumar ', 'chandarkumarmalhi502@gmail.com', 'student', NULL, 'approved', '2026-02-28 04:42:50.953962+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('781be76f-8857-4aed-842f-d2ac4acfaa27', '781be76f-8857-4aed-842f-d2ac4acfaa27', 'Dilsher ', 'dils40732@gmail.com', 'student', NULL, 'approved', '2026-02-28 04:48:47.131777+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('b1c43bc7-dee8-4257-8b15-374c11a9c2ed', 'b1c43bc7-dee8-4257-8b15-374c11a9c2ed', 'Om Pirkas', 'parkashjai124@gmail.com', 'student', NULL, 'approved', '2026-02-28 06:14:38.958494+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('717b9547-5aaa-4947-9a03-5dc6d419f68c', '717b9547-5aaa-4947-9a03-5dc6d419f68c', 'Mehander Singh', 'rathoremehandersingh@gmail.com', 'student', NULL, 'approved', '2026-02-28 07:32:45.925328+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('7ba9b0e1-bcdd-4d44-91e9-8f4043ae415b', '7ba9b0e1-bcdd-4d44-91e9-8f4043ae415b', 'Dolat Rai ', 'dolatrai018@gmail.com', 'student', NULL, 'approved', '2026-02-28 12:59:41.601013+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('66dc3746-cc17-4afc-b67b-17a4eda74e12', '66dc3746-cc17-4afc-b67b-17a4eda74e12', 'Abdulsalam kunbher ', 'salamrahikunbher@gmail.com', 'student', NULL, 'approved', '2026-02-28 14:46:36.101238+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('97af47f1-a0f4-423a-8f22-9a8d8a48588f', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', 'Saroop chand ', 'saroopalam@gmail.com', 'student', NULL, 'approved', '2026-02-28 15:11:31.891465+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('08c23b1e-112e-4291-9c0b-551f16632f05', '08c23b1e-112e-4291-9c0b-551f16632f05', 'Hidayatallah ', 'hidayatallahsamejo2@gmail.com', 'student', NULL, 'approved', '2026-02-28 15:31:51.602297+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', 'Muhammad Khan Nohari', 'muhammadkhannohari720@gmail.com', 'student', NULL, 'approved', '2026-02-28 15:37:26.395344+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('7d38a189-b1d5-401e-aba2-36824936da29', '7d38a189-b1d5-401e-aba2-36824936da29', 'MuneerRaza Samejo', 'samejomuneerraza@gmail.com', 'student', NULL, 'approved', '2026-03-01 04:12:44.950975+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('b23c4b2f-c6a9-470e-bb04-b55f96391760', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', 'Shahnawaz ', 'shahnwazsamejo786@gmail.com', 'student', NULL, 'approved', '2026-02-28 04:45:35.417799+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('94b1710e-1c51-4f1b-87a0-fceaffaebd73', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', 'Narender Kumar ', 'malangnk67@gmail.com', 'student', NULL, 'approved', '2026-03-01 09:08:05.864976+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('494e18ab-b18b-4f7d-b33a-83ac7d3d480f', '494e18ab-b18b-4f7d-b33a-83ac7d3d480f', 'Munawar hussain', 'vehroroadsammamohlla@gmail.com', 'student', NULL, 'approved', '2026-03-06 08:27:22.919565+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('e5540156-8936-4a5c-ab78-4f1b503649f0', 'e5540156-8936-4a5c-ab78-4f1b503649f0', 'Ompirkash Bheel', 'ompirkashbheel417@gmail.com', 'student', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1772362892/avatar_wkzd1o.png', 'approved', '2026-03-01 04:34:32.210517+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', 'Papu', 'papuradhani342@gmail.com', 'student', NULL, 'approved', '2026-03-02 09:51:49.721561+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('71d95693-e5e9-4626-85fc-4a90e261b5b1', '71d95693-e5e9-4626-85fc-4a90e261b5b1', 'Lajpat ', 'lajpatraibheel545@gmail.com', 'student', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1772457500/avatar_jjucov.png', 'approved', '2026-02-28 14:29:43.344451+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('5c2531cd-11ef-40f9-9789-10bc77e16808', '5c2531cd-11ef-40f9-9789-10bc77e16808', 'Rizwan Ali', 'alikkrizwan01@gmail.com', 'student', NULL, 'approved', '2026-03-02 12:15:06.386135+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('c551abc6-369e-4722-8a1f-f442501db0a2', 'c551abc6-369e-4722-8a1f-f442501db0a2', 'Moti Ram', '469mrmb@gmail.com', 'student', NULL, 'approved', '2026-03-04 09:28:45.792532+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('79ea6f3c-4bff-404b-9539-8b64a36a919b', '79ea6f3c-4bff-404b-9539-8b64a36a919b', 'Usama ', 'ranausama000009@gmail.com', 'student', NULL, 'approved', '2026-03-04 09:40:56.148704+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('08a46873-b1cf-4b3e-92b2-37e662a11775', '08a46873-b1cf-4b3e-92b2-37e662a11775', 'Hidayatullah', 'hidayat.wali3600@gmail.com', 'student', NULL, 'approved', '2026-03-06 15:16:12.662412+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('025e3598-2401-4955-91c8-e8d9c32542fb', '025e3598-2401-4955-91c8-e8d9c32542fb', 'Mukesh Kumar', 'mkuk2015@gmail.com', 'student', NULL, 'approved', '2026-03-07 17:27:23.03591+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('26143df4-85ca-4a53-a7d9-ea6560e29bf6', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', 'Muhammad Siddique Rahimoon ', 'muhammadsiddiquerahimoon711@gmail.com', 'student', NULL, 'approved', '2026-02-28 14:50:37.455764+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('38dfd37b-123f-4938-93b3-dca1dfbb4b08', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', 'Anand kumar', 'anandkumarmalhi440@gmail.com', 'student', NULL, 'approved', '2026-03-08 11:50:05.399526+00');
INSERT INTO public.profiles (id, uid, full_name, email, role, avatar_url, status, created_at) VALUES ('9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', '9a6b8a8d-b666-4b9c-bc7e-d9972444c6ac', 'Partab ', 'kumarpartab109@gmail.com', 'student', NULL, 'approved', '2026-03-10 02:34:29.127584+00');


--
-- Data for Name: resources; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('3a50b1df-1408-4c47-b275-f077cfc0e97d', 'Daily Practice Resource', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1772465958/NAVTTC_WEB_DEVELOPMENT_rkzrva_mhrkmo.zip', NULL, NULL, '2026-03-02 15:39:20.355717+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('4f6b6260-e8aa-4da7-bc1e-735ec0d5b554', 'Traffic Light Example', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1772466170/Traffic-Light_vwqcyi_sj29ze.zip', NULL, NULL, '2026-03-02 15:42:54.032254+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('b9c2b178-daa6-4c1e-8a97-17b444e91cd8', 'Day 2 Practice', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1772645706/day2_yzjv3h.html', NULL, NULL, '2026-03-04 17:35:09.01535+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('05697d4c-1208-4071-b766-1d9c9b509bd7', 'Daily Practice Flex', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1772796827/Comment_gx9nth.html', NULL, NULL, '2026-03-06 11:33:50.024665+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('3c24b048-e736-4449-81d8-f20ce4eacb85', 'Daily Practice 5th March 2026', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1772796902/day2_cxyth0.html', NULL, NULL, '2026-03-06 11:35:06.273679+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('f0ea28ee-8b68-4924-aec4-abb271f6b600', 'Flex Practice 9th March 2026', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1773055223/Iincluded_mxaafu.html', NULL, NULL, '2026-03-09 11:20:27.934683+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('0a88f3e7-9eb2-4d3e-92c1-bdf6eb27af5e', 'HTML in Sindhi', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1773055515/html_in_sindhi_k8qjum.pdf', NULL, NULL, '2026-03-09 11:25:17.796846+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('1ae969fa-a2bb-4c24-b4f7-ef023e409b45', 'CSS Notes', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1773056143/CSS_Notes_likbfz.pdf', NULL, NULL, '2026-03-09 11:35:45.966083+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('febe705d-3f0d-491d-8a18-377f94097514', 'HTML CLASS NOTES', 'https://res.cloudinary.com/dwowte8ny/image/upload/v1773056214/Class_Notes_aig0lo.pdf', NULL, NULL, '2026-03-09 11:36:57.564381+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('bbe21414-e68f-430d-a35b-d5154a252fc6', 'Daily Practice Test 10 March 2026', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1773143185/test_y90mry.html', NULL, NULL, '2026-03-10 11:46:28.376389+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('49a295af-32c0-40be-b1bd-daac7f533a3d', 'Practice 11 march 2026', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1773228883/index_hwskln.html', NULL, NULL, '2026-03-11 11:34:46.270864+00', '');
INSERT INTO public.resources (id, title, url, description, uploaded_by, created_at, subtitle) VALUES ('049133a6-521f-4893-8363-a31d55fe411b', 'daily practice 12 march 2026', 'https://res.cloudinary.com/dwowte8ny/raw/upload/v1773316979/test_deztup.html', NULL, NULL, '2026-03-12 12:03:02.57959+00', '');


--
-- Data for Name: submissions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('79d829db-776a-4d4e-82b3-940a58f84f6a', 'b20813dc-fe51-4292-a54b-3201295be84b', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772646368/task1_nuo7pu.html","github":null,"live":null,"timestamp":"2026-03-04T17:46:08.583Z"}', 'graded', '99', 'Excellent Work Tushal Keep it up!', '2026-03-04 17:46:08.583+00', 'Tushal Kumar', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('259facdd-b646-4dec-b196-b416b7852230', 'b20813dc-fe51-4292-a54b-3201295be84b', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772649042/2ndassignment_qjia1m.html","github":null,"live":null,"timestamp":"2026-03-04T18:30:41.437Z"}', 'graded', '99', 'Excellent Work, Keep it up M.Siddique!', '2026-03-04 18:30:41.437+00', 'Muhammad Siddique Rahimon ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('f501f1bd-86f5-4abc-96d1-74c95c6e2adc', 'b20813dc-fe51-4292-a54b-3201295be84b', '805ab41a-0b79-4e31-b0d2-072a072a443b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772690522/First_code_qn6pw7.html","github":null,"live":null,"timestamp":"2026-03-04T18:00:26.426Z"}', 'graded', '90', 'Good work but still needs some improvements', '2026-03-04 18:00:26.426+00', 'Chandar Kumar ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('5d9af2c0-0338-4db4-904d-4815c8390a2a', 'b20813dc-fe51-4292-a54b-3201295be84b', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772701520/Today_Assignment_dux7kn.html","github":null,"live":null,"timestamp":"2026-03-05T09:05:20.599Z"}', 'graded', '99', 'Excellent Work Keep it up!', '2026-03-05 09:05:20.6+00', 'Lajpat ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('439c3924-bd0b-4d77-b3f8-e87f594806e5', 'b20813dc-fe51-4292-a54b-3201295be84b', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772701063/HTML._m3zpvl.html","github":null,"live":null,"timestamp":"2026-03-05T08:57:58.572Z"}', 'graded', '80', 'Good Work but there is some mistakes in your code please review it', '2026-03-05 08:57:58.572+00', 'Muhammad Khan Nohari', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('13fdbc97-2a7a-4589-a171-6e0b56490198', 'b20813dc-fe51-4292-a54b-3201295be84b', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772697768/index_1_2026-03-05_ibl9ob.html","github":null,"live":null,"timestamp":"2026-03-05T08:02:47.968Z"}', 'graded', '99', 'Excellent Work Narender Keep it Up!', '2026-03-05 08:02:47.968+00', 'Narender Kumar ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('ab3148b5-904d-4f81-84c1-e9a39f703e34', 'b20813dc-fe51-4292-a54b-3201295be84b', 'adfe2a8c-2570-4c32-95b2-f70540048848', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772683846/day2_t44e00.html","github":null,"live":null,"timestamp":"2026-03-05T04:10:47.158Z"}', 'graded', '90', 'Good Work', '2026-03-05 04:10:47.158+00', 'Demo Student', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('3421feec-aebb-4a5a-a90e-63c233383b8d', '3327ade9-460f-4b99-97a7-c5f65e591f46', '805ab41a-0b79-4e31-b0d2-072a072a443b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772780449/task1_acexsa.html","github":null,"live":null,"timestamp":"2026-03-05T18:59:15.230Z"}', 'graded', '95', 'Good Work Chandar', '2026-03-05 18:59:15.231+00', 'Chandar Kumar ', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('3bf28406-d668-4175-86bc-8f70519b2691', '3327ade9-460f-4b99-97a7-c5f65e591f46', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772785858/About_Me_vtvmrd.html","github":null,"live":null,"timestamp":"2026-03-06T08:30:59.384Z"}', 'graded', '90', 'Good Work Lajpat but still needs some improvements in your code use <br> tag', '2026-03-06 08:30:59.385+00', 'Lajpat ', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('b8da78a5-fe45-42e8-9727-f0c9519e1f01', '3327ade9-460f-4b99-97a7-c5f65e591f46', 'c551abc6-369e-4722-8a1f-f442501db0a2', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772802927/Marksheet-1_v4i8qt.html","github":null,"live":null,"timestamp":"2026-03-06T13:15:28.882Z"}', 'graded', '50', 'Good but apne jo task diya h woh nh bnaya kuch or banake bhej diya h', '2026-03-06 13:15:28.883+00', 'Moti Ram', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('052834a5-efe0-4da8-bcc7-5ed70aa579ae', 'b20813dc-fe51-4292-a54b-3201295be84b', '7d38a189-b1d5-401e-aba2-36824936da29', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772798728/muneer2_znnasw.html","github":null,"live":null,"timestamp":"2026-03-06T12:05:30.059Z"}', 'graded', '99', 'Excellent Work Muneer Raza Keep it up', '2026-03-06 12:05:30.061+00', 'MuneerRaza Samejo', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('99ff1644-fcc0-40bd-a28a-8c19ac084d9e', '3327ade9-460f-4b99-97a7-c5f65e591f46', '7d38a189-b1d5-401e-aba2-36824936da29', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772797040/muneerr_razotb.html","github":null,"live":null,"timestamp":"2026-03-06T11:37:21.786Z"}', 'graded', '99', 'Excellent work Muneer Raza Keep it Up!', '2026-03-06 11:37:21.789+00', 'MuneerRaza Samejo', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('4c2063c4-5a9f-419d-961c-119ebd0780e3', '3327ade9-460f-4b99-97a7-c5f65e591f46', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772781104/task2_yacajw.html","github":null,"live":null,"timestamp":"2026-03-06T07:11:44.995Z"}', 'graded', '80', 'Good work Narender but still needs some improvements in your code, You didn''t follow the instructions
please see refference asset image for proper instructions', '2026-03-06 07:11:44.998+00', 'Narender Kumar ', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('96ade610-6723-46b2-8124-8f753c775b44', 'b20813dc-fe51-4292-a54b-3201295be84b', '5c5a6e76-6682-4405-bad4-32817d63619e', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772789355/index_s9cbpo.html","github":null,"live":null,"timestamp":"2026-03-06T09:29:15.545Z"}', 'graded', '95', 'Good work but still needs some improvements', '2026-03-06 09:29:15.545+00', 'Rehman ali', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('a1ada0a9-7eb2-482a-99c2-2f6a4df0db58', '3327ade9-460f-4b99-97a7-c5f65e591f46', '5c2531cd-11ef-40f9-9789-10bc77e16808', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772784611/hobbies_ibrkeh.html","github":null,"live":null,"timestamp":"2026-03-06T08:10:09.903Z"}', 'graded', '99', 'Excellent Work Rizwan Keep it Up!', '2026-03-06 08:10:09.903+00', 'Rizwan Ali', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('25afd263-d00c-440b-8e29-c744a026c857', 'b20813dc-fe51-4292-a54b-3201295be84b', '5c2531cd-11ef-40f9-9789-10bc77e16808', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772781021/index_dyjtow.html","github":null,"live":null,"timestamp":"2026-03-06T07:10:20.237Z"}', 'graded', '99', 'Excelent Work Rizwan Keep it Up!', '2026-03-06 07:10:20.237+00', 'Rizwan Ali', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('6d7f565c-b37a-4a96-93a1-08ed7f447805', '3327ade9-460f-4b99-97a7-c5f65e591f46', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772789872/Task2_acw8p9.html","github":null,"live":null,"timestamp":"2026-03-06T09:37:57.569Z"}', 'graded', '99', 'Excellent Work Saroopchand Keep it Up!
', '2026-03-06 09:37:57.569+00', 'Saroop chand ', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('1234adbf-483a-4ea7-a68f-d1facf52abd4', 'b20813dc-fe51-4292-a54b-3201295be84b', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772790469/task1_dwciwg.html","github":null,"live":null,"timestamp":"2026-03-06T09:48:23.162Z"}', 'graded', '95', 'Good Work Shahnawaz but still needs some improvements', '2026-03-06 09:48:23.162+00', 'Shahnawaz ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('2f7ed6c2-9d87-4e1e-8a05-3486acb60f06', '3327ade9-460f-4b99-97a7-c5f65e591f46', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772768830/task2_fwiywd.html","github":null,"live":null,"timestamp":"2026-03-06T03:47:10.525Z"}', 'graded', '99', 'Excellent Work Tushal Keep it Up!', '2026-03-06 03:47:10.526+00', 'Tushal Kumar', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('403e9d35-0023-4663-879d-d4ff16fd25f8', '3327ade9-460f-4b99-97a7-c5f65e591f46', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772824783/tasks2nd_qt3l8k.html","github":null,"live":null,"timestamp":"2026-03-06T19:19:43.308Z"}', 'graded', '99', 'Excellent work Siddique, Keep it up!', '2026-03-06 19:19:43.308+00', 'Muhammad Siddique Rahimon ', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('8534e123-7190-4efd-a576-0e341a678951', 'b20813dc-fe51-4292-a54b-3201295be84b', '79ea6f3c-4bff-404b-9539-8b64a36a919b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772866543/1_vtuedu.html","github":null,"live":null,"timestamp":"2026-03-07T06:55:42.982Z"}', 'graded', '50', 'Good work usama but aap ne dusri assignement bhej di h or yeh topic dusra h please recheck', '2026-03-07 06:55:42.982+00', 'Usama ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('11a0c1c4-c481-42b2-841d-bc77ade5d42f', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772901806/Task3_hncgjc.html","github":null,"live":null,"timestamp":"2026-03-07T16:43:25.148Z"}', 'graded', '99', 'Excellent Work Lajpat Keep it up!', '2026-03-07 16:43:25.149+00', 'Lajpat ', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('33ab47ea-7e9a-4705-92c1-45ef0fb81681', 'b20813dc-fe51-4292-a54b-3201295be84b', 'c551abc6-369e-4722-8a1f-f442501db0a2', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772884059/gulji_bncmhv.html","github":null,"live":null,"timestamp":"2026-03-07T11:47:39.416Z"}', 'graded', '50', 'Good work but you submit another assignement not you have assigned', '2026-03-07 11:47:39.416+00', 'Moti Ram', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('b5df698e-29cc-494f-ba5c-50a19965f6f9', '3327ade9-460f-4b99-97a7-c5f65e591f46', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772901772/day2_ofrb8o.html","github":null,"live":null,"timestamp":"2026-03-07T16:42:52.059Z"}', 'graded', '99', 'Excellent Work Muhammad Khan Keep it up!
', '2026-03-07 16:42:52.06+00', 'Muhammad Khan Nohari', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('b4623e4b-7aff-4d91-9cf2-ed359a76a717', '2b2e649f-6ea8-4aa2-85db-da98b7126703', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772902359/task3_pluvop.html","github":null,"live":null,"timestamp":"2026-03-07T16:52:39.368Z"}', 'graded', '99', 'Excellent Work Tushal Keep it up!', '2026-03-07 16:52:39.369+00', 'Tushal Kumar', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('64de431d-3116-4a5f-a5a4-e32c2ec8ff86', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772982130/index_vqnh1m.html","github":null,"live":null,"timestamp":"2026-03-08T15:02:17.607Z"}', 'graded', '99', 'Excellent Work  Anand Kumar Keep it Up!', '2026-03-08 15:02:17.607+00', 'Anand kumar', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('a7e65860-2779-42bf-9a4b-2df8e2b1106d', '3327ade9-460f-4b99-97a7-c5f65e591f46', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772981577/index_fpc8wk.html","github":null,"live":null,"timestamp":"2026-03-08T14:53:05.290Z"}', 'graded', '90', 'Good Work but still needs an improvement in your task', '2026-03-08 14:53:05.29+00', 'Anand kumar', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('03f0ecc0-7ec1-4be5-b722-ff1fd2fdca72', 'b20813dc-fe51-4292-a54b-3201295be84b', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772980915/INDEX_bqbpmo.HTML","github":null,"live":null,"timestamp":"2026-03-08T14:42:04.325Z"}', 'graded', '95', 'Good Work', '2026-03-08 14:42:04.325+00', 'Anand kumar', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('bf6c0b19-d0db-4247-84bb-85d29d56f9da', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '08a46873-b1cf-4b3e-92b2-37e662a11775', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772959858/Task-3_qcnpzw.html","github":null,"live":null,"timestamp":"2026-03-08T08:50:58.052Z"}', 'graded', '30', 'Good Try but you submit wrong assignment please check it, you didn''t follow instructions properly', '2026-03-08 08:50:58.052+00', 'Hidayatullah', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('0bdaef6e-694f-415d-a6b5-d7ae83f99fd4', 'b20813dc-fe51-4292-a54b-3201295be84b', '08a46873-b1cf-4b3e-92b2-37e662a11775', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772956328/Task_1_vxeqzi.html","github":null,"live":null,"timestamp":"2026-03-08T07:52:07.869Z"}', 'graded', '90', 'Good Work but still needs an improvements', '2026-03-08 07:52:07.869+00', 'Hidayatullah', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('c097dd39-8c3d-4f7b-a91d-cf2ecb8d1706', '2b2e649f-6ea8-4aa2-85db-da98b7126703', 'c551abc6-369e-4722-8a1f-f442501db0a2', '{"file":"https://res.cloudinary.com/dwowte8ny/image/upload/v1772947551/Screenshot_20260308-093754_m1eko9.jpg","github":null,"live":null,"timestamp":"2026-03-08T05:25:52.972Z"}', 'graded', '20', 'Good Try but you didn''t follow instructions properly ', '2026-03-08 05:25:52.976+00', 'Moti Ram', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('89e7dc31-d9d9-44f0-86fc-d376ccc7fd5a', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772905431/task3_xqoy5x.html","github":null,"live":null,"timestamp":"2026-03-07T17:43:50.410Z"}', 'graded', '99', 'Excellent Work Muhammad Siddique Keep it Up!', '2026-03-07 17:43:50.41+00', 'Muhammad Siddique Rahimon ', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('918a8764-6eb4-4e9d-901e-4b9868f94b19', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772963678/task3_tdr9oh.html","github":null,"live":null,"timestamp":"2026-03-08T09:54:37.676Z"}', 'graded', '99', 'Excellent Work Narender Keep it Up!', '2026-03-08 09:54:37.676+00', 'Narender Kumar ', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('cbf2e82e-ae4d-4ebc-a798-9a46f4ab6e8c', '2b2e649f-6ea8-4aa2-85db-da98b7126703', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772911583/index3_kvryuu.html","github":null,"live":null,"timestamp":"2026-03-07T19:26:22.836Z"}', 'graded', '99', 'Excellent Work Om Pirkash Keep it Up!', '2026-03-07 19:26:22.837+00', 'Ompirkash Bheel', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('2086255d-2cae-4c54-aa80-33ee7ad6c616', 'b20813dc-fe51-4292-a54b-3201295be84b', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772908086/1task_b6ixnn.html","github":null,"live":null,"timestamp":"2026-03-07T18:28:06.680Z"}', 'graded', '99', 'Excellent Work Om Pirkash Keep it Up!', '2026-03-07 18:28:06.681+00', 'Ompirkash Bheel', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('eb5b585d-0f95-4ef6-8c64-59fb250dfe75', '3327ade9-460f-4b99-97a7-c5f65e591f46', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772907325/INDEX_mxahiy.html","github":null,"live":null,"timestamp":"2026-03-07T18:15:24.639Z"}', 'graded', '99', 'Excellent Work Om Pirkash Keep it Up!', '2026-03-07 18:15:24.639+00', 'Ompirkash Bheel', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('fd1b559f-51ac-4f90-b6a2-7478769c5c81', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772941063/task3_ihx5rx.html","github":null,"live":null,"timestamp":"2026-03-08T03:37:49.137Z"}', 'graded', '99', 'Excellent Work Saroop Chand Keep it Up!', '2026-03-08 03:37:49.137+00', 'Saroop chand ', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('30f82543-4556-4c77-bbfa-805bff434ecd', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772941008/task3_waig42.html","github":null,"live":null,"timestamp":"2026-03-08T03:36:48.355Z"}', 'graded', '99', 'Excellent Work Abdul Salam Keep it Up!', '2026-03-08 03:36:48.357+00', 'Abdulsalam kunbher ', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('4fa71409-c1e6-4996-b4c6-83fe66c904da', 'b20813dc-fe51-4292-a54b-3201295be84b', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1772987450/task_1_tbwgh3.html","github":null,"live":null,"timestamp":"2026-03-08T16:30:56.461Z"}', 'graded', '99', 'Excellent Work Saroop Chand Keep it Up!', '2026-03-08 16:30:56.461+00', 'Saroop chand ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('ebbdb36e-d50c-467b-9062-dc0fd046eb77', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '805ab41a-0b79-4e31-b0d2-072a072a443b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773030806/Task3_qf6vtk.html","github":null,"live":null,"timestamp":"2026-03-09T04:33:27.305Z"}', 'graded', '99', 'Excellent Work Chandar Keep it Up!', '2026-03-09 04:33:27.306+00', 'Chandar Kumar ', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('16bf23e8-5f5b-45a8-a60e-fe6f2d20324c', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773013618/day3_ifpamb.html","github":null,"live":null,"timestamp":"2026-03-08T23:46:58.669Z"}', 'graded', '99', 'Excellent Work Muhammad Khan Keep it Up!', '2026-03-08 23:46:58.669+00', 'Muhammad Khan Nohari', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('6c3070bd-ba54-45df-8e8c-034e22b65da8', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '5c2531cd-11ef-40f9-9789-10bc77e16808', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773031598/index_oxldmw.html","github":null,"live":null,"timestamp":"2026-03-09T04:46:38.608Z"}', 'graded', '99', 'Excellent Work Rizwan Ali Keep it Up!', '2026-03-09 04:46:38.609+00', 'Rizwan Ali', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('1bce908d-bd8e-4d70-b555-f9fb7686a67e', '3327ade9-460f-4b99-97a7-c5f65e591f46', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773059389/task_2_rdlbtz.html","github":null,"live":null,"timestamp":"2026-03-09T12:29:50.302Z"}', 'graded', '90', 'Good but still need improvements', '2026-03-09 12:29:50.302+00', 'Abdulsalam kunbher ', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('f72ea7fa-0646-4ed1-9fc1-f89357b7bf03', 'b20813dc-fe51-4292-a54b-3201295be84b', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773059278/task1_eqi0ko.html","github":null,"live":null,"timestamp":"2026-03-09T12:27:58.652Z"}', 'graded', '99', 'Excellent Work Abdul Salam Keep it Up!', '2026-03-09 12:27:58.653+00', 'Abdulsalam kunbher ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('557cb3a4-50ae-4b9d-8be9-39426d8ec371', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '5c5a6e76-6682-4405-bad4-32817d63619e', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773051533/myfile_tintks.html","github":null,"live":null,"timestamp":"2026-03-09T10:18:53.242Z"}', 'graded', '95', 'Good Work Rehman Ali Keep it Up!
', '2026-03-09 10:18:53.242+00', 'Rehman ali', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('8307c88f-6f46-445d-904e-0ef72752e4bc', '3327ade9-460f-4b99-97a7-c5f65e591f46', '5c5a6e76-6682-4405-bad4-32817d63619e', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773049801/index_kxtbnl.html","github":null,"live":null,"timestamp":"2026-03-09T09:50:01.409Z"}', 'graded', '99', 'Excellent Work Rehman Ali Keep it Up!', '2026-03-09 09:50:01.409+00', 'Rehman ali', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('43adb1dc-cb5e-4803-bb22-3071f42d8c50', 'b20813dc-fe51-4292-a54b-3201295be84b', '781be76f-8857-4aed-842f-d2ac4acfaa27', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773071677/index_bsesq9.html","github":null,"live":null,"timestamp":"2026-03-09T15:54:41.040Z"}', 'graded', '90', 'Good Work but still needs some improvements', '2026-03-09 15:54:41.041+00', 'Dilsher ', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('13977ea4-88e0-43e6-b5de-bf215b5917fe', '677e9b88-0253-446c-bf34-e6e847094967', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773114952/task4_xs0zyl.zip","github":null,"live":null,"timestamp":"2026-03-10T03:55:52.135Z"}', 'graded', '99', 'Excellent Work Tushal Keep it Up!', '2026-03-10 03:55:52.135+00', 'Tushal Kumar', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('20521371-46f8-4993-a888-dace4c217623', '677e9b88-0253-446c-bf34-e6e847094967', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773146540/tasks4_qzakoa.html","github":null,"live":null,"timestamp":"2026-03-10T12:42:19.397Z"}', 'graded', '99', 'Excellent Work Muhammad Siddique Keep it Up!', '2026-03-10 12:42:19.398+00', 'Muhammad Siddique Rahimoon ', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('95417318-a18a-4838-b7d6-b7cfa4ebff28', '677e9b88-0253-446c-bf34-e6e847094967', '7d38a189-b1d5-401e-aba2-36824936da29', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773133532/muneer14_y2ha9c.html","github":null,"live":null,"timestamp":"2026-03-10T09:05:31.643Z"}', 'graded', '99', 'Excellent Work Muneer Raza Keep it Up!', '2026-03-10 09:05:31.643+00', 'MuneerRaza Samejo', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('0757020d-7024-4678-acfe-d79c7068e79d', '2b2e649f-6ea8-4aa2-85db-da98b7126703', '7d38a189-b1d5-401e-aba2-36824936da29', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773131634/muneer13_nka24z.html","github":null,"live":null,"timestamp":"2026-03-10T08:33:54.246Z"}', 'graded', '99', 'Excellent Work Muneer Raza Keep it Up!', '2026-03-10 08:33:54.247+00', 'MuneerRaza Samejo', '📝 Task 3: Create Lists in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('7e0ef7c6-8b9f-48d2-8c53-ed64d8de60e3', '677e9b88-0253-446c-bf34-e6e847094967', '5c2531cd-11ef-40f9-9789-10bc77e16808', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773137427/task_4_k3wl9v.zip","github":null,"live":null,"timestamp":"2026-03-10T10:10:27.288Z"}', 'graded', '99', 'Excellent Work Rizwan Ali Keep it Up!', '2026-03-10 10:10:27.288+00', 'Rizwan Ali', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('ba3ebb7f-a319-49e7-8326-990aac8ed837', '677e9b88-0253-446c-bf34-e6e847094967', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773136316/task4_rkspjh.zip","github":null,"live":null,"timestamp":"2026-03-10T09:51:58.999Z"}', 'graded', '99', 'Excellent Work Saroop Chand Keep it Up!', '2026-03-10 09:51:58.999+00', 'Saroop chand ', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('f8c30cf5-40e5-46f4-883b-833e07cb67c1', '677e9b88-0253-446c-bf34-e6e847094967', '79ea6f3c-4bff-404b-9539-8b64a36a919b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773131824/task2_v3lxfj.html","github":null,"live":null,"timestamp":"2026-03-10T08:37:01.822Z"}', 'graded', '90', 'Good Work Usama but still need an improvement in your code', '2026-03-10 08:37:01.823+00', 'Usama ', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('7b182980-c869-4555-96f6-c253ae723892', '677e9b88-0253-446c-bf34-e6e847094967', '805ab41a-0b79-4e31-b0d2-072a072a443b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773219810/student_submissions/805ab41a-0b79-4e31-b0d2-072a072a443b/task4_1773219806767_eha72a.zip","github":null,"live":null,"timestamp":"2026-03-11T09:03:29.693Z"}', 'graded', '99', 'Excellent Work Chandar Keep it Up!', '2026-03-11 09:03:29.694+00', 'Chandar Kumar ', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('02e8485f-d847-47d8-b010-081fbc43e714', '677e9b88-0253-446c-bf34-e6e847094967', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773308054/student_submissions/71d95693-e5e9-4626-85fc-4a90e261b5b1/powerful_1773307954116_3pyejj.zip","github":null,"live":null,"timestamp":"2026-03-12T09:34:14.085Z"}', 'submitted', NULL, NULL, '2026-03-12 09:34:14.087+00', 'Lajpat ', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('4ce2627f-ce9a-4746-8747-86bd075a61b0', '677e9b88-0253-446c-bf34-e6e847094967', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773220383/student_submissions/e5540156-8936-4a5c-ab78-4f1b503649f0/task4_1773220378635_2hbdpt.zip","github":null,"live":null,"timestamp":"2026-03-11T09:13:03.347Z"}', 'graded', '99', 'Excellent Work Om Pirkash Keep it Up!', '2026-03-11 09:13:03.347+00', 'Ompirkash Bheel', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('b5c251d5-16e3-4939-9b77-1b4fb256794e', '677e9b88-0253-446c-bf34-e6e847094967', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773213486/student_submissions/94b1710e-1c51-4f1b-87a0-fceaffaebd73/task_4_1773213486362_lbzb8f.zip","github":null,"live":null,"timestamp":"2026-03-11T07:18:08.297Z"}', 'graded', '99', 'Excellent Work Narender Keep it Up!', '2026-03-11 07:18:08.298+00', 'Narender Kumar ', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('081ef42a-ecec-464c-952a-297be93a9dba', 'b20813dc-fe51-4292-a54b-3201295be84b', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773221201/student_submissions/bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6/index_1773221198964_huo960.html","github":null,"live":null,"timestamp":"2026-03-11T09:26:40.725Z"}', 'graded', '99', 'Excellent Work Papu Keep it Up!', '2026-03-11 09:26:40.727+00', 'Papu', 'Task 1: Headings Practice (H1 to H6)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('7becb335-fea0-4dd0-bf6d-08ee655e5729', '677e9b88-0253-446c-bf34-e6e847094967', '38dfd37b-123f-4938-93b3-dca1dfbb4b08', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773159165/TASK_4_xmg6iv.rar","github":null,"live":null,"timestamp":"2026-03-10T16:12:53.718Z"}', 'graded', '99', 'Excellent Work', '2026-03-10 16:12:53.718+00', 'Anand kumar', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('dbad6fe2-5998-42d7-ad83-7158ea229082', '677e9b88-0253-446c-bf34-e6e847094967', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773216187/student_submissions/66dc3746-cc17-4afc-b67b-17a4eda74e12/Task_4__1773216183670_r7pjex.zip","github":null,"live":null,"timestamp":"2026-03-11T08:03:08.751Z"}', 'graded', '99', 'Excellent Work Abdul Salam Keep it Up!', '2026-03-11 08:03:08.755+00', 'Abdulsalam kunbher ', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('066f2b0b-afa8-4cce-92a1-b483478d7181', '677e9b88-0253-446c-bf34-e6e847094967', '5c5a6e76-6682-4405-bad4-32817d63619e', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773220824/student_submissions/5c5a6e76-6682-4405-bad4-32817d63619e/task_4_1773220806018_zfg4di.zip","github":null,"live":null,"timestamp":"2026-03-11T09:20:25.073Z"}', 'graded', '80', 'Good work Rehman but still needs some improvements in your code', '2026-03-11 09:20:25.074+00', 'Rehman ali', '📝 Task 4: Links and Images in HTML');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('0e45f534-10ed-4d09-be88-3b6f812b3449', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773253609/task5_y450pn.html","github":null,"live":null,"timestamp":"2026-03-11T18:26:48.774Z"}', 'graded', '99', 'Excellent Work Tushal Keep it Up!', '2026-03-11 18:26:48.775+00', 'Tushal Kumar', '📝 Task 5 – Styled Student Table (HTML + CSS)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('5a135020-d9a9-4a93-9e05-cf36c817fa1d', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', '66dc3746-cc17-4afc-b67b-17a4eda74e12', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773252428/student_submissions/66dc3746-cc17-4afc-b67b-17a4eda74e12/Task_5__1773252426527_225fmq.zip","github":null,"live":null,"timestamp":"2026-03-11T18:07:12.826Z"}', 'graded', '99', 'Excellent Work Abdul Salam Keep it Up!', '2026-03-11 18:07:12.83+00', 'Abdulsalam kunbher ', '📝 Task 5 – Styled Student Table (HTML + CSS)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('d8b0947b-514f-4cec-8141-c57c5332e44e', '3327ade9-460f-4b99-97a7-c5f65e591f46', '781be76f-8857-4aed-842f-d2ac4acfaa27', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773286114/student_submissions/781be76f-8857-4aed-842f-d2ac4acfaa27/task2_1773286111404_fgwxwx.html","github":null,"live":null,"timestamp":"2026-03-12T03:28:34.559Z"}', 'graded', '80', 'Good but still needs and improvement', '2026-03-12 03:28:34.56+00', 'Dilsher ', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('dd39089c-5a33-4bcf-b489-45b6006ac12e', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', 'e5540156-8936-4a5c-ab78-4f1b503649f0', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773292797/student_submissions/e5540156-8936-4a5c-ab78-4f1b503649f0/task5_1773292788598_b34p4o.zip","github":null,"live":null,"timestamp":"2026-03-12T05:19:56.998Z"}', 'graded', '80', 'Good but still needs an improvements', '2026-03-12 05:19:56.999+00', 'Ompirkash Bheel', '📝 Task 5 – Styled Student Table (HTML + CSS)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('935176b3-0f08-4897-a202-a22cefd816c7', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', '97af47f1-a0f4-423a-8f22-9a8d8a48588f', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773291074/student_submissions/97af47f1-a0f4-423a-8f22-9a8d8a48588f/_m_task5_1773291074537_emmqao.html","github":null,"live":null,"timestamp":"2026-03-12T04:51:17.482Z"}', 'graded', '80', 'Good Work still needs improvements', '2026-03-12 04:51:17.484+00', 'Saroop chand ', '📝 Task 5 – Styled Student Table (HTML + CSS)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('16717c11-0658-4c6b-8811-21dde2a321c5', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773297041/student_submissions/26143df4-85ca-4a53-a7d9-ea6560e29bf6/tasks5_1773297038829_fmjaho.html","github":null,"live":null,"timestamp":"2026-03-12T06:30:41.612Z"}', 'submitted', NULL, NULL, '2026-03-12 06:30:41.613+00', 'Muhammad Siddique Rahimoon ', '📝 Task 5 – Styled Student Table (HTML + CSS)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('e3a50aea-5d46-42c7-a5ab-6b1af8f358e5', '3327ade9-460f-4b99-97a7-c5f65e591f46', '717b9547-5aaa-4947-9a03-5dc6d419f68c', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773302835/student_submissions/717b9547-5aaa-4947-9a03-5dc6d419f68c/Task2_1773302833387_1q5ny8.html","github":null,"live":null,"timestamp":"2026-03-12T08:07:15.025Z"}', 'submitted', NULL, NULL, '2026-03-12 08:07:15.028+00', 'Mehander Singh', '📝 Task 2: Paragraph and Text Formatting');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('2a6d5cbc-f4ea-4220-a568-8a377e8923d3', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', '805ab41a-0b79-4e31-b0d2-072a072a443b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773308448/student_submissions/805ab41a-0b79-4e31-b0d2-072a072a443b/Student_table_1773308447224_s2udcn.html","github":null,"live":null,"timestamp":"2026-03-12T09:40:48.984Z"}', 'submitted', NULL, NULL, '2026-03-12 09:40:48.984+00', 'Chandar Kumar ', '📝 Task 5 – Styled Student Table (HTML + CSS)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('edfe1331-40c8-443b-9ff5-46206cc407df', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', '79ea6f3c-4bff-404b-9539-8b64a36a919b', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773314604/student_submissions/79ea6f3c-4bff-404b-9539-8b64a36a919b/task5_1773314580888_k0lwg2.html","github":null,"live":null,"timestamp":"2026-03-12T11:23:24.081Z"}', 'submitted', NULL, NULL, '2026-03-12 11:23:24.081+00', 'Usama ', '📝 Task 5 – Styled Student Table (HTML + CSS)');
INSERT INTO public.submissions (id, task_id, student_id, content, status, grade, feedback, submitted_at, student_name, task_title) VALUES ('384235e3-e449-49e6-b9e6-1d27a43dce25', 'd9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', '71d95693-e5e9-4626-85fc-4a90e261b5b1', '{"file":"https://res.cloudinary.com/dwowte8ny/raw/upload/v1773421278/student_submissions/71d95693-e5e9-4626-85fc-4a90e261b5b1/task5_1773421276713_f10twc.html","github":null,"live":null,"timestamp":"2026-03-13T17:01:19.944Z"}', 'submitted', NULL, NULL, '2026-03-13 17:01:19.945+00', 'Lajpat ', '📝 Task 5 – Styled Student Table (HTML + CSS)');


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.system_settings (key, value, updated_at) VALUES ('brevo_api_key', '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', '2026-03-07 19:42:27.460988+00');


--
-- Data for Name: task_comments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tasks (id, title, description, deadline, created_by, created_at, hints) VALUES ('b20813dc-fe51-4292-a54b-3201295be84b', 'Task 1: Headings Practice (H1 to H6)', 'Create a simple HTML page using all heading tags from h1 to h6.

Instructions:

Create an HTML file (e.g., task1.html)

Inside the <body>, add the following:

<h1> → Your Name

<h2> → Your Course/Field (e.g., Web Development)

<h3> → Your Institute/School

<h4> → Your City

<h5> → Your Favorite Hobby

<h6> → Today’s Date

<br><strong>Reference Asset:</strong> <a href="https://res.cloudinary.com/dwowte8ny/image/upload/v1772645569/Screenshot_2026-03-04_223137_kbxqwo.png" target="_blank" class="text-indigo-500 hover:underline">View Attachment</a>', '2026-03-05 10:00:00+00', NULL, '2026-03-04 17:32:50.1903+00', '');
INSERT INTO public.tasks (id, title, description, deadline, created_by, created_at, hints) VALUES ('3327ade9-460f-4b99-97a7-c5f65e591f46', '📝 Task 2: Paragraph and Text Formatting', 'Create a simple HTML page using paragraph and basic text formatting tags.

Instructions:

Create an HTML file (e.g., task2.html)

Inside the <body>, add the following:

A main heading (h1) with the text: About Me

A paragraph describing yourself (4–5 lines)

Inside the paragraph, use these formatting tags:

<b> for bold text

<i> for italic text

<u> for underlined text

<br> for a line break

Example idea: Write about your studies, skills, or hobbies.

<br><strong>Reference Asset:</strong> <a href="https://res.cloudinary.com/dwowte8ny/image/upload/v1772733832/Screenshot_2026-03-04_223137_irv1ne.png" target="_blank" class="text-indigo-500 hover:underline">View Attachment</a>', '2026-03-06 11:00:00+00', NULL, '2026-03-05 18:03:55.567214+00', '');
INSERT INTO public.tasks (id, title, description, deadline, created_by, created_at, hints) VALUES ('2b2e649f-6ea8-4aa2-85db-da98b7126703', '📝 Task 3: Create Lists in HTML', 'Create a simple HTML page using ordered and unordered lists.

Instructions:

Create an HTML file (e.g., task3.html)

Inside the <body>, add the following:

A heading (h1) with the text: My Skills

An unordered list (ul) containing at least 5 skills

Then add:

Another heading (h2) with the text: Daily Routine

An ordered list (ol) containing at least 5 daily activities

<br><strong>Reference Asset:</strong> <a href="https://res.cloudinary.com/dwowte8ny/image/upload/v1772900343/task3_q6f3wx.png" target="_blank" class="text-indigo-500 hover:underline">View Attachment</a>', '2026-03-09 11:00:00+00', NULL, '2026-03-07 16:19:04.68855+00', '');
INSERT INTO public.tasks (id, title, description, deadline, created_by, created_at, hints) VALUES ('d9bf939e-7620-4ea6-b0a5-4f3ae9dda0c2', '📝 Task 5 – Styled Student Table (HTML + CSS)', 'Create a Student Information Table using HTML and CSS.

Requirements

Add a page heading:
Student Information Table

Create a table with 6 columns:

ID

Name

Course

City

Email

Status

Add at least 6 student records.

CSS Requirements

Table should be center aligned

Table width 70%

Add padding inside cells

Header background color should be dark

Text color of header should be white

Add hover effect on rows

Add border-collapse

<br><strong>Reference Asset:</strong> <a href="https://res.cloudinary.com/dwowte8ny/image/upload/v1773246913/task5_tvrk5f.png" target="_blank" class="text-indigo-500 hover:underline">View Attachment</a>', '2026-03-12 11:00:00+00', NULL, '2026-03-11 16:34:22.397859+00', '');
INSERT INTO public.tasks (id, title, description, deadline, created_by, created_at, hints) VALUES ('677e9b88-0253-446c-bf34-e6e847094967', '📝 Task 4: Links and Images in HTML', 'Create a simple HTML page using links and images.

Instructions

Create an HTML file (e.g., task4.html)

Inside the <body>, add the following:

A heading (h1) with the text: My Favorite Website

Add a link (anchor tag) that opens Google in a new tab

Add another heading (h2) with the text: My Favorite Image

Insert an image using the <img> tag

Set width = 300px

Add alt text for the image

<br><strong>Reference Asset:</strong> <a href="https://res.cloudinary.com/dwowte8ny/image/upload/v1773070663/task4_jzggl3.png" target="_blank" class="text-indigo-500 hover:underline">View Attachment</a>', '2026-03-10 11:00:00+00', NULL, '2026-03-09 15:37:44.382807+00', '');


--
-- Data for Name: user_achievements; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('8153c95b-ffbd-4561-8b99-c869cefb3734', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'first_login', '2026-02-27 16:16:33.887406+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('6a899797-3a52-4241-acd1-c10f27000627', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'code_runner', '2026-02-27 20:56:04.817242+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('acb8b833-e608-4b37-9b02-f574598758ce', 'e5540156-8936-4a5c-ab78-4f1b503649f0', 'code_runner', '2026-03-01 10:59:56.461743+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('095170bb-d0ce-4105-8278-dfdac0ddbea4', '781be76f-8857-4aed-842f-d2ac4acfaa27', 'code_runner', '2026-03-01 12:28:43.417369+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('39ba7052-a956-42ad-a7fb-6015ebb08ccf', 'c6769364-3029-4cb3-8b72-ba24c7c5ee5a', 'code_runner', '2026-03-01 14:27:44.11698+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('eab0b4ee-bb4b-447c-b7b7-4ba049f84086', '805ab41a-0b79-4e31-b0d2-072a072a443b', 'code_runner', '2026-03-01 16:06:07.809528+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('8bde2b13-bc3a-480e-a6b9-1972b378e4a3', '94b1710e-1c51-4f1b-87a0-fceaffaebd73', 'code_runner', '2026-03-01 16:14:12.694508+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('a1d0354d-ca77-4f8a-b824-82d9113b3694', 'b23c4b2f-c6a9-470e-bb04-b55f96391760', 'code_runner', '2026-03-02 10:15:40.155373+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('e022a059-0110-4caf-8a91-ac7a36e0d434', '71d95693-e5e9-4626-85fc-4a90e261b5b1', 'code_runner', '2026-03-02 13:19:06.092307+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('fad3435e-1141-49bc-8712-b0fad41ffe0d', 'adfe2a8c-2570-4c32-95b2-f70540048848', 'streak_3', '2026-03-02 14:24:21.298388+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('7e93ee23-a2a3-4173-ac20-531280d72859', '05dafca0-fdd7-4acc-bba5-ec4ee9aca6be', 'code_runner', '2026-03-02 14:41:40.274125+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('82316f64-4a57-40a2-9e73-8abaa3b237f1', '5c2531cd-11ef-40f9-9789-10bc77e16808', 'code_runner', '2026-03-03 06:11:44.167243+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('1296500a-5912-4837-bf44-72148cfac2b7', '26143df4-85ca-4a53-a7d9-ea6560e29bf6', 'code_runner', '2026-03-04 18:31:03.247549+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('e4d9ae97-3c23-43fd-b1cf-2bd2302c8193', '79ea6f3c-4bff-404b-9539-8b64a36a919b', 'code_runner', '2026-03-04 18:38:39.181923+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('9ddf2f91-fd43-4f67-8c27-cfe16bff0190', 'bc98e8b0-d4b8-4d42-9825-a33bf2fb5cb6', 'code_runner', '2026-03-05 04:23:21.889028+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('f534aa47-0b30-446a-bb06-3cd5835d4861', '08c23b1e-112e-4291-9c0b-551f16632f05', 'code_runner', '2026-03-05 15:33:54.755953+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('08b7a7f2-6aa5-4095-b038-e1e7523ad77a', '5c5a6e76-6682-4405-bad4-32817d63619e', 'code_runner', '2026-03-06 09:14:21.404107+00');
INSERT INTO public.user_achievements (id, user_id, badge_key, earned_at) VALUES ('eb1cc210-bd77-4f79-a6a5-2680e1f28c1d', '66dc3746-cc17-4afc-b67b-17a4eda74e12', 'code_runner', '2026-03-07 12:55:00.474136+00');


--
-- Data for Name: user_arcade_progress; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: messages_2026_03_10; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_03_11; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_03_12; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_03_13; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_03_14; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_03_15; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_03_16; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116024918, '2026-02-27 11:37:39');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116045059, '2026-02-27 13:09:44');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116050929, '2026-02-27 13:09:44');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116051442, '2026-02-27 13:09:45');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116212300, '2026-02-27 13:09:46');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116213355, '2026-02-27 13:09:46');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116213934, '2026-02-27 13:09:47');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116214523, '2026-02-27 13:09:48');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211122062447, '2026-02-27 13:09:48');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211124070109, '2026-02-27 13:09:49');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211202204204, '2026-02-27 13:09:50');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211202204605, '2026-02-27 13:09:50');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211210212804, '2026-02-27 13:09:52');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211228014915, '2026-02-27 13:09:53');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220107221237, '2026-02-27 13:09:54');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220228202821, '2026-02-27 13:09:54');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220312004840, '2026-02-27 13:09:55');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220603231003, '2026-02-27 13:09:56');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220603232444, '2026-02-27 13:09:56');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220615214548, '2026-02-27 13:09:57');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220712093339, '2026-02-27 13:09:58');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220908172859, '2026-02-27 13:09:58');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220916233421, '2026-02-27 13:09:59');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230119133233, '2026-02-27 13:10:00');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230128025114, '2026-02-27 13:10:00');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230128025212, '2026-02-27 13:10:01');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230227211149, '2026-02-27 13:10:02');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230228184745, '2026-02-27 13:10:02');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230308225145, '2026-02-27 13:10:03');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230328144023, '2026-02-27 13:10:04');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231018144023, '2026-02-27 13:10:04');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144023, '2026-02-27 13:10:05');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144024, '2026-02-27 13:10:06');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144025, '2026-02-27 13:10:07');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240108234812, '2026-02-27 13:10:07');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240109165339, '2026-02-27 13:10:08');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240227174441, '2026-02-27 13:10:09');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240311171622, '2026-02-27 13:10:10');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240321100241, '2026-02-27 13:10:11');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240401105812, '2026-02-27 13:10:13');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240418121054, '2026-02-27 13:10:14');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240523004032, '2026-02-27 13:10:16');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240618124746, '2026-02-27 13:10:17');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240801235015, '2026-02-27 13:10:17');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240805133720, '2026-02-27 13:10:18');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240827160934, '2026-02-27 13:10:18');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240919163303, '2026-02-27 13:10:19');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240919163305, '2026-02-27 13:10:20');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241019105805, '2026-02-27 13:10:21');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241030150047, '2026-02-27 13:10:23');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241108114728, '2026-02-27 13:10:24');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241121104152, '2026-02-27 13:10:24');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241130184212, '2026-02-27 13:10:25');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241220035512, '2026-02-27 13:10:26');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241220123912, '2026-02-27 13:10:26');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241224161212, '2026-02-27 13:10:27');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250107150512, '2026-02-27 13:10:28');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250110162412, '2026-02-27 13:10:28');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250123174212, '2026-02-27 13:10:29');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250128220012, '2026-02-27 13:10:30');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250506224012, '2026-02-27 13:10:30');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250523164012, '2026-02-27 13:10:31');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250714121412, '2026-02-27 13:10:31');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250905041441, '2026-02-27 13:10:32');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251103001201, '2026-02-27 13:10:32');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251120212548, '2026-02-27 13:10:33');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251120215549, '2026-02-27 13:10:34');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20260218120000, '2026-02-27 13:10:35');


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

INSERT INTO realtime.subscription (id, subscription_id, entity, filters, claims, created_at, action_filter) OVERRIDING SYSTEM VALUE VALUES (1724, '3f21bb32-1f09-11f1-a998-0a58a9feac02', 'public.submissions', '{}', '{"aal": "aal1", "amr": [{"method": "password", "timestamp": 1773417135}], "aud": "authenticated", "exp": 1773427825, "iat": 1773424225, "iss": "https://fnkctvhrilynnmphdxuo.supabase.co/auth/v1", "sub": "a01b174b-4c80-4fc7-a47d-db292f995fe3", "role": "authenticated", "email": "mkuk2013@gmail.com", "phone": "", "session_id": "a3b7762f-88ce-4087-aa59-8a7b0b89d0f2", "app_metadata": {"provider": "email", "providers": []}, "is_anonymous": false, "user_metadata": {"role": "admin"}}', '2026-03-13 18:20:02.661857', 'INSERT');
INSERT INTO realtime.subscription (id, subscription_id, entity, filters, claims, created_at, action_filter) OVERRIDING SYSTEM VALUE VALUES (1723, '3f23085c-1f09-11f1-a7bc-0a58a9feac02', 'public.admin_chat_messages', '{}', '{"aal": "aal1", "amr": [{"method": "password", "timestamp": 1773417135}], "aud": "authenticated", "exp": 1773427825, "iat": 1773424225, "iss": "https://fnkctvhrilynnmphdxuo.supabase.co/auth/v1", "sub": "a01b174b-4c80-4fc7-a47d-db292f995fe3", "role": "authenticated", "email": "mkuk2013@gmail.com", "phone": "", "session_id": "a3b7762f-88ce-4087-aa59-8a7b0b89d0f2", "app_metadata": {"provider": "email", "providers": []}, "is_anonymous": false, "user_metadata": {"role": "admin"}}', '2026-03-13 18:20:02.29517', 'INSERT');


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (0, 'create-migrations-table', 'e18db593bcde2aca2a408c4d1100f6abba2195df', '2026-02-27 11:37:38.622607');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (1, 'initialmigration', '6ab16121fbaa08bbd11b712d05f358f9b555d777', '2026-02-27 11:37:38.90912');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (2, 'storage-schema', 'f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd', '2026-02-27 11:37:38.912574');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (3, 'pathtoken-column', '2cb1b0004b817b29d5b0a971af16bafeede4b70d', '2026-02-27 11:37:39.783651');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (4, 'add-migrations-rls', '427c5b63fe1c5937495d9c635c263ee7a5905058', '2026-02-27 11:37:40.115009');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (5, 'add-size-functions', '79e081a1455b63666c1294a440f8ad4b1e6a7f84', '2026-02-27 11:37:40.119667');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (6, 'change-column-name-in-get-size', 'ded78e2f1b5d7e616117897e6443a925965b30d2', '2026-02-27 11:37:40.139981');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (7, 'add-rls-to-buckets', 'e7e7f86adbc51049f341dfe8d30256c1abca17aa', '2026-02-27 11:37:40.15133');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (8, 'add-public-to-buckets', 'fd670db39ed65f9d08b01db09d6202503ca2bab3', '2026-02-27 11:37:40.154603');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (9, 'fix-search-function', 'af597a1b590c70519b464a4ab3be54490712796b', '2026-02-27 11:37:40.164566');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (10, 'search-files-search-function', 'b595f05e92f7e91211af1bbfe9c6a13bb3391e16', '2026-02-27 11:37:40.174965');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (11, 'add-trigger-to-auto-update-updated_at-column', '7425bdb14366d1739fa8a18c83100636d74dcaa2', '2026-02-27 11:37:40.178674');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (12, 'add-automatic-avif-detection-flag', '8e92e1266eb29518b6a4c5313ab8f29dd0d08df9', '2026-02-27 11:37:40.191442');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (13, 'add-bucket-custom-limits', 'cce962054138135cd9a8c4bcd531598684b25e7d', '2026-02-27 11:37:40.195016');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (14, 'use-bytes-for-max-size', '941c41b346f9802b411f06f30e972ad4744dad27', '2026-02-27 11:38:10.811201');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (15, 'add-can-insert-object-function', '934146bc38ead475f4ef4b555c524ee5d66799e5', '2026-02-27 11:38:10.889059');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (16, 'add-version', '76debf38d3fd07dcfc747ca49096457d95b1221b', '2026-02-27 11:38:10.899682');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (17, 'drop-owner-foreign-key', 'f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101', '2026-02-27 11:38:10.904865');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (18, 'add_owner_id_column_deprecate_owner', 'e7a511b379110b08e2f214be852c35414749fe66', '2026-02-27 11:38:10.909685');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (19, 'alter-default-value-objects-id', '02e5e22a78626187e00d173dc45f58fa66a4f043', '2026-02-27 11:38:10.916692');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (20, 'list-objects-with-delimiter', 'cd694ae708e51ba82bf012bba00caf4f3b6393b7', '2026-02-27 11:38:10.924544');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (21, 's3-multipart-uploads', '8c804d4a566c40cd1e4cc5b3725a664a9303657f', '2026-02-27 11:38:10.931707');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (22, 's3-multipart-uploads-big-ints', '9737dc258d2397953c9953d9b86920b8be0cdb73', '2026-02-27 11:38:10.95015');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (23, 'optimize-search-function', '9d7e604cddc4b56a5422dc68c9313f4a1b6f132c', '2026-02-27 11:38:10.959915');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (24, 'operation-function', '8312e37c2bf9e76bbe841aa5fda889206d2bf8aa', '2026-02-27 11:38:10.96545');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (25, 'custom-metadata', 'd974c6057c3db1c1f847afa0e291e6165693b990', '2026-02-27 11:38:10.970979');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (26, 'objects-prefixes', '215cabcb7f78121892a5a2037a09fedf9a1ae322', '2026-02-27 11:38:10.976446');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (27, 'search-v2', '859ba38092ac96eb3964d83bf53ccc0b141663a6', '2026-02-27 11:38:10.981109');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (28, 'object-bucket-name-sorting', 'c73a2b5b5d4041e39705814fd3a1b95502d38ce4', '2026-02-27 11:38:10.985784');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (29, 'create-prefixes', 'ad2c1207f76703d11a9f9007f821620017a66c21', '2026-02-27 11:38:10.990376');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (30, 'update-object-levels', '2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6', '2026-02-27 11:38:10.994912');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (31, 'objects-level-index', 'b40367c14c3440ec75f19bbce2d71e914ddd3da0', '2026-02-27 11:38:10.99957');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (32, 'backward-compatible-index-on-objects', 'e0c37182b0f7aee3efd823298fb3c76f1042c0f7', '2026-02-27 11:38:11.00438');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (33, 'backward-compatible-index-on-prefixes', 'b480e99ed951e0900f033ec4eb34b5bdcb4e3d49', '2026-02-27 11:38:11.009104');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (34, 'optimize-search-function-v1', 'ca80a3dc7bfef894df17108785ce29a7fc8ee456', '2026-02-27 11:38:11.01383');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (35, 'add-insert-trigger-prefixes', '458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc', '2026-02-27 11:38:11.018677');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (36, 'optimise-existing-functions', '6ae5fca6af5c55abe95369cd4f93985d1814ca8f', '2026-02-27 11:38:11.023409');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (37, 'add-bucket-name-length-trigger', '3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1', '2026-02-27 11:38:11.028176');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (38, 'iceberg-catalog-flag-on-buckets', '02716b81ceec9705aed84aa1501657095b32e5c5', '2026-02-27 11:38:11.034519');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (39, 'add-search-v2-sort-support', '6706c5f2928846abee18461279799ad12b279b78', '2026-02-27 11:38:11.047473');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (40, 'fix-prefix-race-conditions-optimized', '7ad69982ae2d372b21f48fc4829ae9752c518f6b', '2026-02-27 11:38:11.052064');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (41, 'add-object-level-update-trigger', '07fcf1a22165849b7a029deed059ffcde08d1ae0', '2026-02-27 11:38:11.056687');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (42, 'rollback-prefix-triggers', '771479077764adc09e2ea2043eb627503c034cd4', '2026-02-27 11:38:11.061613');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (43, 'fix-object-level', '84b35d6caca9d937478ad8a797491f38b8c2979f', '2026-02-27 11:38:11.066381');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (44, 'vector-bucket-type', '99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3', '2026-02-27 11:38:11.071137');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (45, 'vector-buckets', '049e27196d77a7cb76497a85afae669d8b230953', '2026-02-27 11:38:11.077446');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (46, 'buckets-objects-grants', 'fedeb96d60fefd8e02ab3ded9fbde05632f84aed', '2026-02-27 11:38:11.095385');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (47, 'iceberg-table-metadata', '649df56855c24d8b36dd4cc1aeb8251aa9ad42c2', '2026-02-27 11:38:11.101477');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (48, 'iceberg-catalog-ids', 'e0e8b460c609b9999ccd0df9ad14294613eed939', '2026-02-27 11:38:11.107159');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (49, 'buckets-objects-grants-postgres', '072b1195d0d5a2f888af6b2302a1938dd94b8b3d', '2026-02-27 11:38:11.139936');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (50, 'search-v2-optimised', '6323ac4f850aa14e7387eb32102869578b5bd478', '2026-02-27 11:38:11.148486');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (51, 'index-backward-compatible-search', '2ee395d433f76e38bcd3856debaf6e0e5b674011', '2026-02-27 11:38:11.175696');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (52, 'drop-not-used-indexes-and-functions', '5cc44c8696749ac11dd0dc37f2a3802075f3a171', '2026-02-27 11:38:11.177875');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (53, 'drop-index-lower-name', 'd0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854', '2026-02-27 11:38:11.18806');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (54, 'drop-index-object-level', '6289e048b1472da17c31a7eba1ded625a6457e67', '2026-02-27 11:38:11.191117');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (55, 'prevent-direct-deletes', '262a4798d5e0f2e7c8970232e03ce8be695d5819', '2026-02-27 11:38:11.193196');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (56, 'fix-optimized-search-function', 'cb58526ebc23048049fd5bf2fd148d18b04a2073', '2026-02-27 11:38:11.199507');


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 994, true);


--
-- Name: arcade_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.arcade_config_id_seq', 1, false);


--
-- Name: exam_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exam_settings_id_seq', 1, false);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1724, true);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: admin_chat_messages admin_chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_pkey PRIMARY KEY (id);


--
-- Name: arcade_config arcade_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arcade_config
    ADD CONSTRAINT arcade_config_pkey PRIMARY KEY (id);


--
-- Name: exam_results exam_results_certificate_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_certificate_id_key UNIQUE (certificate_id);


--
-- Name: exam_results exam_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_pkey PRIMARY KEY (id);


--
-- Name: exam_settings exam_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_settings
    ADD CONSTRAINT exam_settings_pkey PRIMARY KEY (id);


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: game_scores game_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_scores
    ADD CONSTRAINT game_scores_pkey PRIMARY KEY (id);


--
-- Name: notices notices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT notices_pkey PRIMARY KEY (id);


--
-- Name: personal_storage personal_storage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_storage
    ADD CONSTRAINT personal_storage_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_email_key UNIQUE (email);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: resources resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_task_id_student_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_task_id_student_id_key UNIQUE (task_id, student_id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (key);


--
-- Name: task_comments task_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_user_id_badge_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_badge_key_key UNIQUE (user_id, badge_key);


--
-- Name: user_arcade_progress user_arcade_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_arcade_progress
    ADD CONSTRAINT user_arcade_progress_pkey PRIMARY KEY (user_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_03_10 messages_2026_03_10_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_03_10
    ADD CONSTRAINT messages_2026_03_10_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_03_11 messages_2026_03_11_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_03_11
    ADD CONSTRAINT messages_2026_03_11_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_03_12 messages_2026_03_12_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_03_12
    ADD CONSTRAINT messages_2026_03_12_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_03_13 messages_2026_03_13_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_03_13
    ADD CONSTRAINT messages_2026_03_13_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_03_14 messages_2026_03_14_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_03_14
    ADD CONSTRAINT messages_2026_03_14_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_03_15 messages_2026_03_15_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_03_15
    ADD CONSTRAINT messages_2026_03_15_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_03_16 messages_2026_03_16_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_03_16
    ADD CONSTRAINT messages_2026_03_16_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_03_10_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_03_10_inserted_at_topic_idx ON realtime.messages_2026_03_10 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_03_11_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_03_11_inserted_at_topic_idx ON realtime.messages_2026_03_11 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_03_12_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_03_12_inserted_at_topic_idx ON realtime.messages_2026_03_12 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_03_13_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_03_13_inserted_at_topic_idx ON realtime.messages_2026_03_13 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_03_14_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_03_14_inserted_at_topic_idx ON realtime.messages_2026_03_14 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_03_15_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_03_15_inserted_at_topic_idx ON realtime.messages_2026_03_15 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_03_16_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_03_16_inserted_at_topic_idx ON realtime.messages_2026_03_16 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_key ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: messages_2026_03_10_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_03_10_inserted_at_topic_idx;


--
-- Name: messages_2026_03_10_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_03_10_pkey;


--
-- Name: messages_2026_03_11_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_03_11_inserted_at_topic_idx;


--
-- Name: messages_2026_03_11_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_03_11_pkey;


--
-- Name: messages_2026_03_12_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_03_12_inserted_at_topic_idx;


--
-- Name: messages_2026_03_12_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_03_12_pkey;


--
-- Name: messages_2026_03_13_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_03_13_inserted_at_topic_idx;


--
-- Name: messages_2026_03_13_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_03_13_pkey;


--
-- Name: messages_2026_03_14_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_03_14_inserted_at_topic_idx;


--
-- Name: messages_2026_03_14_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_03_14_pkey;


--
-- Name: messages_2026_03_15_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_03_15_inserted_at_topic_idx;


--
-- Name: messages_2026_03_15_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_03_15_pkey;


--
-- Name: messages_2026_03_16_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_03_16_inserted_at_topic_idx;


--
-- Name: messages_2026_03_16_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_03_16_pkey;


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: admin_chat_messages admin_chat_messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: admin_chat_messages admin_chat_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: exam_results exam_results_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: feedback feedback_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: game_scores game_scores_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_scores
    ADD CONSTRAINT game_scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: notices notices_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT notices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: personal_storage personal_storage_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_storage
    ADD CONSTRAINT personal_storage_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: resources resources_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.profiles(id);


--
-- Name: submissions submissions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: submissions submissions_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_comments task_comments_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_comments task_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: user_achievements user_achievements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: user_arcade_progress user_arcade_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_arcade_progress
    ADD CONSTRAINT user_arcade_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: user_achievements Achievements viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Achievements viewable by everyone" ON public.user_achievements FOR SELECT USING (true);


--
-- Name: notices Active notices are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Active notices are viewable by everyone" ON public.notices FOR SELECT USING (((is_active = true) OR public.is_admin()));


--
-- Name: feedback Admins can delete feedback; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete feedback" ON public.feedback FOR DELETE USING (public.is_admin());


--
-- Name: profiles Admins can delete profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete profiles" ON public.profiles FOR DELETE USING (public.is_admin());


--
-- Name: personal_storage Admins can manage all files; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage all files" ON public.personal_storage TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.uid = auth.uid()) AND (profiles.role = 'admin'::text)))));


--
-- Name: arcade_config Admins can manage arcade config; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage arcade config" ON public.arcade_config USING (public.is_admin());


--
-- Name: feedback Admins can manage feedback; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage feedback" ON public.feedback FOR UPDATE USING (public.is_admin());


--
-- Name: notices Admins can manage notices; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage notices" ON public.notices USING (public.is_admin());


--
-- Name: resources Admins can manage resources; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage resources" ON public.resources USING (public.is_admin());


--
-- Name: tasks Admins can manage tasks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage tasks" ON public.tasks USING (public.is_admin());


--
-- Name: feedback Admins can view feedback; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view feedback" ON public.feedback FOR SELECT USING ((public.is_admin() OR (auth.uid() = student_id)));


--
-- Name: system_settings Allow authenticated users to insert/update settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to insert/update settings" ON public.system_settings TO authenticated USING (true) WITH CHECK (true);


--
-- Name: system_settings Allow authenticated users to read settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to read settings" ON public.system_settings FOR SELECT TO authenticated USING (true);


--
-- Name: submissions Allow students to delete their submissions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow students to delete their submissions" ON public.submissions FOR DELETE USING (true);


--
-- Name: submissions Allow students to update their submissions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow students to update their submissions" ON public.submissions FOR UPDATE USING (true);


--
-- Name: arcade_config Arcade config visible to everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Arcade config visible to everyone" ON public.arcade_config FOR SELECT USING (true);


--
-- Name: user_arcade_progress Arcade progress viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Arcade progress viewable by everyone" ON public.user_arcade_progress FOR SELECT USING (true);


--
-- Name: task_comments Comments viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Comments viewable by everyone" ON public.task_comments FOR SELECT USING (true);


--
-- Name: exam_settings Exam settings visible to everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Exam settings visible to everyone" ON public.exam_settings FOR SELECT USING (true);


--
-- Name: game_scores Game scores viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Game scores viewable by everyone" ON public.game_scores FOR SELECT USING (true);


--
-- Name: exam_results Only admins can delete exam results; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can delete exam results" ON public.exam_results FOR DELETE USING (public.is_admin());


--
-- Name: submissions Only admins can delete submissions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can delete submissions" ON public.submissions FOR DELETE USING (public.is_admin());


--
-- Name: exam_settings Only admins can update exam settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can update exam settings" ON public.exam_settings USING (public.is_admin());


--
-- Name: exam_results Only admins can update/delete exam results; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can update/delete exam results" ON public.exam_results FOR UPDATE USING (public.is_admin());


--
-- Name: profiles Public profiles are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);


--
-- Name: resources Resources viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Resources viewable by everyone" ON public.resources FOR SELECT USING (true);


--
-- Name: exam_results Students can insert their own exam results; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Students can insert their own exam results" ON public.exam_results FOR INSERT WITH CHECK ((auth.uid() = student_id));


--
-- Name: exam_results Students can view their own exam results; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Students can view their own exam results" ON public.exam_results FOR SELECT USING (((auth.uid() = student_id) OR public.is_admin()));


--
-- Name: tasks Tasks viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Tasks viewable by everyone" ON public.tasks FOR SELECT USING (true);


--
-- Name: profiles Users and Admins can insert profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users and Admins can insert profiles" ON public.profiles FOR INSERT WITH CHECK (((auth.uid() = id) OR public.is_admin()));


--
-- Name: profiles Users and Admins can update profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users and Admins can update profiles" ON public.profiles FOR UPDATE USING (((auth.uid() = id) OR public.is_admin()));


--
-- Name: submissions Users can create their own submissions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create their own submissions" ON public.submissions FOR INSERT WITH CHECK ((auth.uid() = student_id));


--
-- Name: task_comments Users can delete own comments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own comments" ON public.task_comments FOR DELETE USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- Name: personal_storage Users can delete their own storage; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own storage" ON public.personal_storage FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: task_comments Users can insert own comments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own comments" ON public.task_comments FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_achievements Users can insert their own achievements; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own achievements" ON public.user_achievements FOR INSERT WITH CHECK (((auth.uid() = user_id) OR public.is_admin()));


--
-- Name: admin_chat_messages Users can insert their own messages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own messages" ON public.admin_chat_messages FOR INSERT WITH CHECK ((auth.uid() = sender_id));


--
-- Name: personal_storage Users can insert to their own storage; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert to their own storage" ON public.personal_storage FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: game_scores Users can manage own game scores; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage own game scores" ON public.game_scores USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- Name: personal_storage Users can manage their own files; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own files" ON public.personal_storage TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: feedback Users can submit feedback; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can submit feedback" ON public.feedback FOR INSERT WITH CHECK ((auth.uid() = student_id));


--
-- Name: task_comments Users can update own comments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own comments" ON public.task_comments FOR UPDATE USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- Name: user_arcade_progress Users can update their own arcade progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own arcade progress" ON public.user_arcade_progress USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- Name: submissions Users can update their own pending submissions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own pending submissions" ON public.submissions FOR UPDATE USING ((((auth.uid() = student_id) AND (status = 'pending'::text)) OR public.is_admin()));


--
-- Name: personal_storage Users can update their own storage; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own storage" ON public.personal_storage FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: admin_chat_messages Users can view their own messages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own messages" ON public.admin_chat_messages FOR SELECT USING (((auth.uid() = sender_id) OR (auth.uid() = receiver_id)));


--
-- Name: personal_storage Users can view their own storage; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own storage" ON public.personal_storage FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: submissions Users can view their own submissions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own submissions" ON public.submissions FOR SELECT USING (((auth.uid() = student_id) OR public.is_admin()));


--
-- Name: admin_chat_messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_chat_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: arcade_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.arcade_config ENABLE ROW LEVEL SECURITY;

--
-- Name: exam_results; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;

--
-- Name: exam_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.exam_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: feedback; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

--
-- Name: game_scores; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.game_scores ENABLE ROW LEVEL SECURITY;

--
-- Name: notices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

--
-- Name: personal_storage; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.personal_storage ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: resources; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

--
-- Name: submissions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;

--
-- Name: system_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: task_comments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

--
-- Name: tasks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

--
-- Name: user_achievements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

--
-- Name: user_arcade_progress; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_arcade_progress ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime_messages_publication; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime_messages_publication WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime admin_chat_messages; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.admin_chat_messages;


--
-- Name: supabase_realtime submissions; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.submissions;


--
-- Name: supabase_realtime_messages_publication messages; Type: PUBLICATION TABLE; Schema: realtime; Owner: -
--

ALTER PUBLICATION supabase_realtime_messages_publication ADD TABLE ONLY realtime.messages;


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict XmtWcI44lXOBtOHvtB4m8VT4HvAbPkOZywS3if8ASVvA2Fk7a3mkt5jlaHfezdP

