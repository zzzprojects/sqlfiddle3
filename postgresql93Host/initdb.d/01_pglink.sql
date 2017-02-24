-- Run this file first, before other postgres sql scripts.
-- Ex: psql -U postgres postgres < postgres_initial_setup.sql

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;

CREATE DATABASE db_template ENCODING 'utf8';