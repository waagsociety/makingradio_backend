--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.6
-- Dumped by pg_dump version 9.4.0
-- Started on 2016-04-07 15:38:22 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA IF NOT EXISTS public;

ALTER SCHEMA public OWNER TO postgres;

COMMENT ON SCHEMA public IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'gammaagent') THEN

      CREATE ROLE gammaagent LOGIN
        ENCRYPTED PASSWORD 'md5bb10ec1348e0952788b8c2a169735bd3'
        NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

   END IF;
END
$body$;


CREATE DATABASE gamma
  WITH OWNER = gammaagent
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'en_US.UTF-8'
       LC_CTYPE = 'en_US.UTF-8'
       CONNECTION LIMIT = -1;

\connect gamma

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;


CREATE TABLE IF NOT EXISTS measures
(
  srv_ts timestamp with time zone NOT NULL,
  id_device bigint NOT NULL,
  id_measure bigint NOT NULL,
  value numeric,
  max_value numeric,
  min_value numeric,
  location geometry NOT NULL,
  message text,
  CONSTRAINT id_timestamp PRIMARY KEY (id_device, srv_ts)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE measures
  OWNER TO gammaagent;


-- CREATE TABLE IF NOT EXISTS sensorparameters
-- (
--   id bigint NOT NULL,
--   devicename text,
--   description text,
--   CONSTRAINT sensornames_id PRIMARY KEY (id)
-- )
-- WITH (
--   OIDS=FALSE
-- );
-- ALTER TABLE sensorparameters
--   OWNER TO gammaagent;
