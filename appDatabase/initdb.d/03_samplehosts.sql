--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 9.6.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

--
-- Data for Name: hosts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO hosts VALUES (1, 15, 'jdbc:postgresql://postgresql93Host:5432/#databaseName#', 'postgres', 'postgres', 'password', NULL, false);
INSERT INTO hosts VALUES (2, 9, 'jdbc:mysql://mysql56Host:3306/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8', 'mysql', 'root', 'password', NULL, false);
INSERT INTO hosts VALUES (3, 4, 'jdbc:oracle:thin:@//oracle11gHost:1521/xe', 'XE', 'system', 'password', NULL, false);
INSERT INTO hosts VALUES (7, 16, 'jdbc:postgresql://postgresql96Host:5432/#databaseName#', 'postgres', 'postgres', 'password', NULL, false);
INSERT INTO hosts VALUES (4, 6, 'jdbc:jtds:sqlserver://mssql2017Host:1433/#databaseName#', 'master', 'sa', 'SQLServerPassword!', NULL, false);
INSERT INTO hosts VALUES (6, 3, 'jdbc:jtds:sqlserver://mssql2017Host:1433/#databaseName#', 'master', 'sa', 'SQLServerPassword!', NULL, false);
INSERT INTO hosts VALUES (8, 18, 'jdbc:jtds:sqlserver://mssql2017Host:1433/#databaseName#', 'master', 'sa', 'SQLServerPassword!', NULL, false);


--
-- Name: hosts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('hosts_id_seq', 8, true);


--
-- PostgreSQL database dump complete
--
