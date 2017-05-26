
--
-- Data for Name: hosts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY hosts (id, db_type_id, jdbc_url_template, default_database, admin_username, admin_password) FROM stdin;
1	15	jdbc:postgresql://postgresql93Host:5432/#databaseName#	postgres	postgres	password
2	9	jdbc:mysql://mysql56Host:3306/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8	mysql	root	password
3	4	jdbc:oracle:thin:@//oracle11gHost:1521/xe	XE	system	password
4	6	jdbc:jtds:sqlserver://sqlserver2014Host:1433/#databaseName#	master	sa	SQLServerPassword
6	3	jdbc:jtds:sqlserver://sqlserver2014Host:1433/#databaseName#	master	sa	SQLServerPassword
\.


--
-- Name: hosts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('hosts_id_seq', 5, true);
