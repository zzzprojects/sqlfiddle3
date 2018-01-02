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
-- Data for Name: db_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO db_types VALUES (4, 'Oracle 11g R2', 'Oracle', '
create user user_#databaseName# identified by "#databaseName#" default tablespace fiddledata profile fiddleusers
/
grant create session, create synonym, create table, create type, create view, create materialized view, create procedure, create sequence, create trigger to user_#databaseName#
/
alter user user_#databaseName# quota 5M on fiddledata
/
create table system.deferred_#databaseName# (val NUMBER(1) CONSTRAINT deferred_#databaseName#_ck CHECK(val =1) DEFERRABLE INITIALLY DEFERRED)
/
grant insert on system.deferred_#databaseName# to user_#databaseName#
/
', 'oracle.jdbc.OracleDriver', 'DECLARE
  l_cnt integer;
BEGIN
  EXECUTE IMMEDIATE ''alter user user_#databaseName# account lock'';
  FOR x IN (SELECT *
              FROM v$session
             WHERE username = ''USER_#databaseName#'')
  LOOP
    EXECUTE IMMEDIATE ''alter system disconnect session '''''' || x.sid || '','' || x.serial# || '''''' IMMEDIATE'';
  END LOOP;

  -- Wait for as long as it takes for all the sessions to go away
  LOOP
    SELECT COUNT(*)
      INTO l_cnt
      FROM v$session
     WHERE username = ''USER_#databaseName#'';
    EXIT WHEN l_cnt = 0;
    dbms_lock.sleep( 1 );
  END LOOP;

 FOR cc IN (SELECT owner, table_name FROM all_tables WHERE tablespace_name = upper(''fiddledata'') AND table_lock = ''DISABLED'' and owner = upper(''user_#databaseName#'')) LOOP
  EXECUTE IMMEDIATE ''ALTER TABLE "'' || cc.owner || ''"."'' || cc.table_name || ''" ENABLE TABLE LOCK'';
END LOOP;  EXECUTE IMMEDIATE ''drop user user_#databaseName# cascade'';

  EXECUTE IMMEDIATE ''drop table system.deferred_#databaseName#'';
END;', NULL, '/', 'Oracle does not support multiple statements in batch.  Separate each statement with a line consisting of a single /, and do not terminate statements with semicolons.', '4/c0be1/1', '
	explain plan set STATEMENT_ID = ''#schema_short_code#/#query_id#'' for
', '


/

select ''<pre>'' || dbms_xplan.display_plan(format=>''ALL'', statement_id => ''#schema_short_code#/#query_id#'') || ''</pre>'' as XPLAN FROM dual', NULL, 'host', NULL, 1, 'select schema_name from (select distinct lower(replace(USERNAME, ''USER'', ''DB'')) as schema_name from all_users) tmp');
INSERT INTO db_types VALUES (7, 'SQLite (WebSQL)', 'SQLite', NULL, 'websql', NULL, NULL, NULL, NULL, '7/44b90/1', NULL, NULL, NULL, 'browser', NULL, 1, NULL);
INSERT INTO db_types VALUES (5, 'SQLite (SQL.js)', 'SQLite', '
CREATE USER user_#databaseName# PASSWORD ''#databaseName#''', 'sqljs', NULL, NULL, NULL, NULL, '5/b5362/1', NULL, NULL, NULL, 'browser', NULL, 1, NULL);
INSERT INTO db_types VALUES (9, 'MySQL 5.6', 'MySQL', '
CREATE database db_#databaseName#  default CHARACTER SET = utf8 default COLLATE = utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW,ALTER ROUTINE,CREATE ROUTINE,TRIGGER,EXECUTE,REFERENCES
 ON db_#databaseName#.* TO user_#databaseName#@''%'' IDENTIFIED BY ''#databaseName#'';
GRANT SELECT ON performance_schema.* TO user_#databaseName#@''%'';
', 'org.gjt.mm.mysql.Driver', '
 DROP DATABASE db_#databaseName#; drop user user_#databaseName#@''%'';
', NULL, NULL, NULL, '9/dcb16/1', 'explain extended ', NULL, NULL, 'host', NULL, 1, 'show databases');
INSERT INTO db_types VALUES (15, 'PostgreSQL 9.3', 'PostgreSQL', '

CREATE USER user_#databaseName# PASSWORD ''#databaseName#'';
CREATE DATABASE db_#databaseName# OWNER user_#databaseName# ENCODING ''UTF8'' TEMPLATE db_template;
commit;
ALTER USER user_#databaseName# SET statement_timeout = 30000;
SELECT dblink_connect(''#databaseName#'', ''dbname=db_#databaseName# hostaddr=127.0.0.1 user=postgres'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE deferred_check (id INT PRIMARY KEY)'');
SELECT dblink_exec(''#databaseName#'', ''INSERT INTO deferred_check VALUES (1)'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE db_#databaseName#.public.deferred_#databaseName# (fk INT NOT NULL)'');
SELECT dblink_exec(''#databaseName#'', ''ALTER TABLE ONLY deferred_#databaseName# ADD CONSTRAINT deferred_#databaseName#_ref FOREIGN KEY (fk) REFERENCES deferred_check(id) DEFERRABLE INITIALLY DEFERRED'');
SELECT dblink_exec(''#databaseName#'', ''GRANT INSERT ON deferred_#databaseName# TO user_#databaseName#'');
SELECT dblink_disconnect(''#databaseName#'');

', 'org.postgresql.Driver', 'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE upper(pg_stat_activity.datname) = upper(''DB_#databaseName#''); DROP DATABASE db_#databaseName#;DROP USER user_#databaseName#;', NULL, NULL, NULL, '15/35773/1', 'explain ', NULL, NULL, 'host', NULL, 1, 'select schema_name from (select datname as schema_name from pg_database) t');
INSERT INTO db_types VALUES (1, 'PostgreSQL 9.1', 'PostgreSQL', '

CREATE USER user_#databaseName# PASSWORD ''#databaseName#'';
CREATE DATABASE db_#databaseName# OWNER user_#databaseName# ENCODING ''UTF8'' TEMPLATE db_template;
commit;
ALTER USER user_#databaseName# SET statement_timeout = 30000;
SELECT dblink_connect(''#databaseName#'', ''dbname=db_#databaseName# hostaddr=127.0.0.1'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE deferred_check (id INT PRIMARY KEY)'');
SELECT dblink_exec(''#databaseName#'', ''INSERT INTO deferred_check VALUES (1)'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE db_#databaseName#.public.deferred_#databaseName# (fk INT NOT NULL)'');
SELECT dblink_exec(''#databaseName#'', ''ALTER TABLE ONLY deferred_#databaseName# ADD CONSTRAINT deferred_#databaseName#_ref FOREIGN KEY (fk) REFERENCES deferred_check(id) DEFERRABLE INITIALLY DEFERRED'');
SELECT dblink_exec(''#databaseName#'', ''GRANT INSERT ON deferred_#databaseName# TO user_#databaseName#'');
SELECT dblink_disconnect(''#databaseName#'');

', 'org.postgresql.Driver', 'SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE upper(pg_stat_activity.datname) = ''DB_#databaseName#''; DROP DATABASE db_#databaseName#;DROP USER user_#databaseName#;', NULL, NULL, 'Separate multiple statements in PostgreSQL by terminating each one with a semicolon.', '1/6ccc5/2', 'explain ', NULL, NULL, 'host', NULL, 0, 'select schema_name from (select datname as schema_name from pg_database) t');
INSERT INTO db_types VALUES (2, 'MySQL 5.5', 'MySQL', '
CREATE database db_#databaseName#  default CHARACTER SET = utf8 default COLLATE = utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW,ALTER ROUTINE,CREATE ROUTINE,TRIGGER,EXECUTE,REFERENCES
 ON db_#databaseName#.* TO user_#databaseName#@''%'' IDENTIFIED BY ''#databaseName#'';
', 'org.gjt.mm.mysql.Driver', '
 DROP DATABASE db_#databaseName#; drop user user_#databaseName#@''%'';
', 'allowMultiQueries=true', NULL, 'Separate multiple statements in MySQL by terminating each one with a semicolon.', '2/dcb16/1', 'explain extended ', NULL, NULL, 'host', NULL, 0, 'show databases');
INSERT INTO db_types VALUES (8, 'MySQL 5.1', 'MySQL', '
CREATE database db_#databaseName#  default CHARACTER SET = utf8 default COLLATE = utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW,ALTER ROUTINE,CREATE ROUTINE,TRIGGER,EXECUTE,REFERENCES
 ON db_#databaseName#.* TO user_#databaseName#@''%'' IDENTIFIED BY ''#databaseName#'';
', 'org.gjt.mm.mysql.Driver', '
 DROP DATABASE db_#databaseName#; drop user user_#databaseName#@''%'';
', NULL, NULL, NULL, '8/a2581/1', 'explain extended ', NULL, NULL, 'host', NULL, 0, 'show databases');
INSERT INTO db_types VALUES (11, 'PostgreSQL 8.4', 'PostgreSQL', '

CREATE USER user_#databaseName# PASSWORD ''#databaseName#'';
CREATE DATABASE db_#databaseName# OWNER user_#databaseName# ENCODING ''UTF8'' TEMPLATE db_template;
commit;
ALTER USER user_#databaseName# SET statement_timeout = 30000;
SELECT dblink_connect(''#databaseName#'', ''dbname=db_#databaseName# hostaddr=127.0.0.1'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE deferred_check (id INT PRIMARY KEY)'');
SELECT dblink_exec(''#databaseName#'', ''INSERT INTO deferred_check VALUES (1)'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE db_#databaseName#.public.deferred_#databaseName# (fk INT NOT NULL)'');
SELECT dblink_exec(''#databaseName#'', ''ALTER TABLE ONLY deferred_#databaseName# ADD CONSTRAINT deferred_#databaseName#_ref FOREIGN KEY (fk) REFERENCES deferred_check(id) DEFERRABLE INITIALLY DEFERRED'');
SELECT dblink_exec(''#databaseName#'', ''GRANT INSERT ON deferred_#databaseName# TO user_#databaseName#'');
SELECT dblink_disconnect(''#databaseName#'');

', 'org.postgresql.Driver', 'SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE upper(pg_stat_activity.datname) = ''DB_#databaseName#''; DROP DATABASE db_#databaseName#;DROP USER user_#databaseName#;', NULL, NULL, NULL, '11/6d80e/1', 'explain ', NULL, NULL, 'host', NULL, 0, 'select schema_name from (select datname as schema_name from pg_database) t');
INSERT INTO db_types VALUES (12, 'PostgreSQL 9.2', 'PostgreSQL', '

CREATE USER user_#databaseName# PASSWORD ''#databaseName#'';
CREATE DATABASE db_#databaseName# OWNER user_#databaseName# ENCODING ''UTF8'' TEMPLATE db_template;
commit;
ALTER USER user_#databaseName# SET statement_timeout = 30000;
SELECT dblink_connect(''#databaseName#'', ''dbname=db_#databaseName# hostaddr=127.0.0.1'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE deferred_check (id INT PRIMARY KEY)'');
SELECT dblink_exec(''#databaseName#'', ''INSERT INTO deferred_check VALUES (1)'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE db_#databaseName#.public.deferred_#databaseName# (fk INT NOT NULL)'');
SELECT dblink_exec(''#databaseName#'', ''ALTER TABLE ONLY deferred_#databaseName# ADD CONSTRAINT deferred_#databaseName#_ref FOREIGN KEY (fk) REFERENCES deferred_check(id) DEFERRABLE INITIALLY DEFERRED'');
SELECT dblink_exec(''#databaseName#'', ''GRANT INSERT ON deferred_#databaseName# TO user_#databaseName#'');
SELECT dblink_disconnect(''#databaseName#'');

', 'org.postgresql.Driver', 'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE upper(pg_stat_activity.datname) = ''DB_#databaseName#''; DROP DATABASE db_#databaseName#;DROP USER user_#databaseName#;', NULL, NULL, NULL, '12/6d80e/1', 'explain ', NULL, NULL, 'host', NULL, 0, 'select schema_name from (select datname as schema_name from pg_database) t');
INSERT INTO db_types VALUES (13, 'MySQL 5.7', 'MySQL', '
CREATE database db_#databaseName#  default CHARACTER SET = utf8 default COLLATE = utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX,CREATE TEMPORARY TABLES,CREATE VIEW,SHOW VIEW,ALTER ROUTINE,CREATE ROUTINE,TRIGGER,EXECUTE,REFERENCES
 ON db_#databaseName#.* TO user_#databaseName#@''%'' IDENTIFIED BY ''#databaseName#'';
', 'org.gjt.mm.mysql.Driver', '
 DROP DATABASE db_#databaseName#; drop user user_#databaseName#@''%'';
', 'allowMultiQueries=true', NULL, 'Separate multiple statements in MySQL by terminating each one with a semicolon.', '2/a2581/1', 'explain extended ', NULL, NULL, 'host', NULL, 0, 'show databases');
INSERT INTO db_types VALUES (10, 'PostgreSQL 8.3', 'PostgreSQL', '

CREATE USER user_#databaseName# PASSWORD ''#databaseName#'';
CREATE DATABASE db_#databaseName# OWNER user_#databaseName# ENCODING ''UTF8'' TEMPLATE db_template;
commit;
ALTER USER user_#databaseName# SET statement_timeout = 30000;
SELECT dblink_connect(''#databaseName#'', ''dbname=db_#databaseName# hostaddr=127.0.0.1'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE deferred_check (id INT PRIMARY KEY)'');
SELECT dblink_exec(''#databaseName#'', ''INSERT INTO deferred_check VALUES (1)'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE db_#databaseName#.public.deferred_#databaseName# (fk INT NOT NULL)'');
SELECT dblink_exec(''#databaseName#'', ''ALTER TABLE ONLY deferred_#databaseName# ADD CONSTRAINT deferred_#databaseName#_ref FOREIGN KEY (fk) REFERENCES deferred_check(id) DEFERRABLE INITIALLY DEFERRED'');
SELECT dblink_exec(''#databaseName#'', ''GRANT INSERT ON deferred_#databaseName# TO user_#databaseName#'');
SELECT dblink_disconnect(''#databaseName#'');

', 'org.postgresql.Driver', 'SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE upper(pg_stat_activity.datname) = ''DB_#databaseName#'';  DROP DATABASE db_#databaseName#;DROP USER user_#databaseName#;', NULL, NULL, NULL, '10/f9585/1', 'explain ', NULL, NULL, 'host', NULL, 0, 'select schema_name from (select datname as schema_name from pg_database) t');
INSERT INTO db_types VALUES (16, 'PostgreSQL 9.6', 'PostgreSQL', '

CREATE USER user_#databaseName# PASSWORD ''#databaseName#'';
CREATE DATABASE db_#databaseName# OWNER user_#databaseName# ENCODING ''UTF8'' TEMPLATE db_template;
commit;
ALTER USER user_#databaseName# SET statement_timeout = 30000;
SELECT dblink_connect(''#databaseName#'', ''dbname=db_#databaseName# hostaddr=127.0.0.1 user=postgres'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE deferred_check (id INT PRIMARY KEY)'');
SELECT dblink_exec(''#databaseName#'', ''INSERT INTO deferred_check VALUES (1)'');
SELECT dblink_exec(''#databaseName#'', ''CREATE TABLE db_#databaseName#.public.deferred_#databaseName# (fk INT NOT NULL)'');
SELECT dblink_exec(''#databaseName#'', ''ALTER TABLE ONLY deferred_#databaseName# ADD CONSTRAINT deferred_#databaseName#_ref FOREIGN KEY (fk) REFERENCES deferred_check(id) DEFERRABLE INITIALLY DEFERRED'');
SELECT dblink_exec(''#databaseName#'', ''GRANT INSERT ON deferred_#databaseName# TO user_#databaseName#'');
SELECT dblink_disconnect(''#databaseName#'');

', 'org.postgresql.Driver', 'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE upper(pg_stat_activity.datname) = upper(''DB_#databaseName#''); DROP DATABASE db_#databaseName#;DROP USER user_#databaseName#;', NULL, NULL, NULL, '16/69b4b/1', 'explain ', NULL, NULL, 'host', NULL, 1, 'select schema_name from (select datname as schema_name from pg_database) t');
INSERT INTO db_types VALUES (6, 'MS SQL Server 2014', 'SQL Server', 'CREATE DATABASE db_#databaseName#;
GO

ALTER DATABASE db_#databaseName# SET COMPATIBILITY_LEVEL = 120;
GO

USE db_#databaseName#;
GO

CREATE LOGIN user_#databaseName#
WITH PASSWORD = ''#databaseName#'', CHECK_POLICY = OFF;
GO

CREATE USER user_#databaseName#;
GO

GRANT
CREATE TABLE,
CREATE TYPE,
CREATE VIEW,
CREATE PROCEDURE,
CREATE FUNCTION,
CREATE FULLTEXT CATALOG,
EXECUTE,
DELETE,
INSERT,
REFERENCES,
SELECT,
SHOWPLAN,
UPDATE
TO user_#databaseName#;
GO



ALTER LOGIN user_#databaseName# WITH DEFAULT_DATABASE=db_#databaseName#;
GO

GRANT ALTER ON SCHEMA::dbo TO user_#databaseName#;
GO

use master;

', 'net.sourceforge.jtds.jdbc.Driver', 'exec dbo.clearDBUsers ''db_#databaseName#'';
GO
drop database db_#databaseName#;
GO
drop login user_#databaseName#;
', NULL, 'GO', NULL, '6/a7540/1', '
SET SHOWPLAN_XML ON;
GO
', '
GO
SET SHOWPLAN_XML OFF', '<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt"
  xmlns:s="http://schemas.microsoft.com/sqlserver/2004/07/showplan"
  exclude-result-prefixes="msxsl s xsl">
  <xsl:output method="html" indent="no" omit-xml-declaration="yes" />

  <!-- Disable built-in recursive processing templates -->
  <xsl:template match="*|/|text()|@*" mode="NodeLabel2" />
  <xsl:template match="*|/|text()|@*" mode="ToolTipDescription" />
  <xsl:template match="*|/|text()|@*" mode="ToolTipDetails" />

  <!-- Default template -->
  <xsl:template match="/">
    <xsl:apply-templates select="s:ShowPlanXML" />
  </xsl:template>

  <!-- Outermost div that contains all statement plans. -->
  <xsl:template match="s:ShowPlanXML">
    <div class="qp-root">
      <xsl:apply-templates select="s:BatchSequence/s:Batch/s:Statements/s:StmtSimple" />
    </div>
  </xsl:template>

  <!-- Matches a branch in the query plan (either an operation or a statement) -->
  <xsl:template match="s:RelOp|s:StmtSimple">
    <div class="qp-tr">
      <div>
        <div class="qp-node">
          <xsl:apply-templates select="." mode="NodeIcon" />
          <xsl:apply-templates select="." mode="NodeLabel" />
          <xsl:apply-templates select="." mode="NodeLabel2" />
          <xsl:apply-templates select="." mode="NodeCostLabel" />
          <xsl:call-template name="ToolTip" />
        </div>
      </div>
      <div><xsl:apply-templates select="*/s:RelOp" /></div>
    </div>
  </xsl:template>

  <!-- Writes the tool tip -->
  <xsl:template name="ToolTip">
    <div class="qp-tt">
      <div class="qp-tt-header"><xsl:value-of select="@PhysicalOp | @StatementType" /></div>
      <div><xsl:apply-templates select="." mode="ToolTipDescription" /></div>
      <xsl:call-template name="ToolTipGrid" />
      <xsl:apply-templates select="* | @* | */* | */@*" mode="ToolTipDetails" />
    </div>
  </xsl:template>

  <!-- Writes the grid of node properties to the tool tip -->
  <xsl:template name="ToolTipGrid">
    <table>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="s:QueryPlan/@CachedPlanSize" />
        <xsl:with-param name="Label">Cached plan size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(s:QueryPlan/@CachedPlanSize, '' B'')" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Physical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@PhysicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Logical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@LogicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Actual Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualRows" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateIO" />
        <xsl:with-param name="Label">Estimated I/O Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateIO" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateCPU" />
        <xsl:with-param name="Label">Estimated CPU Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateCPU" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <!-- TODO: Estimated Number of Executions -->
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Number of Executions</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualExecutions" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Degree of Parallelism</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@DegreeOfParallelism" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Memory Grant</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@MemoryGrant" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateIO | @EstimateCPU" />
        <xsl:with-param name="Label">Estimated Operator Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:variable name="EstimatedOperatorCost">
            <xsl:call-template name="EstimatedOperatorCost" />
          </xsl:variable>
          <xsl:variable name="TotalCost">
            <xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" />
          </xsl:variable>

          <xsl:call-template name="round">
            <xsl:with-param name="value" select="$EstimatedOperatorCost" />
          </xsl:call-template>
          (<xsl:value-of select="format-number(number($EstimatedOperatorCost) div number($TotalCost), ''0%'')" />)
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
        <xsl:with-param name="Label">Estimated Subtree Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Estimated Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="@StatementEstRows | @EstimateRows" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@AvgRowSize" />
        <xsl:with-param name="Label">Estimated Row Size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(@AvgRowSize, '' B'')" />
      </xsl:call-template>
      <!-- TODO: Actual Rebinds
           TODO: Actual Rewinds -->
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="s:IndexScan/@Ordered" />
        <xsl:with-param name="Label">Ordered</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:choose>
            <xsl:when test="s:IndexScan/@Ordered = 1">True</xsl:when>
            <xsl:otherwise>False</xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Node ID</xsl:with-param>
        <xsl:with-param name="Value" select="@NodeId" />
      </xsl:call-template>
    </table>
  </xsl:template>

  <!-- Calculates the estimated operator cost. -->
  <xsl:template name="EstimatedOperatorCost">
    <xsl:variable name="EstimateIO">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateIO" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="EstimateCPU">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateCPU" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="number($EstimateIO) + number($EstimateCPU)" />
  </xsl:template>

  <!-- Renders a row in the tool tip details table. -->
  <xsl:template name="ToolTipRow">
    <xsl:param name="Label" />
    <xsl:param name="Value" />
    <xsl:param name="Condition" select="$Value" />
    <xsl:if test="$Condition">
      <tr>
        <th><xsl:value-of select="$Label" /></th>
        <td><xsl:value-of select="$Value" /></td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- Prints the name of an object. -->
  <xsl:template match="s:Object | s:ColumnReference" mode="ObjectName">
    <xsl:param name="ExcludeDatabaseName" select="false()" />
    <xsl:choose>
      <xsl:when test="$ExcludeDatabaseName">
        <xsl:for-each select="@Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="@Database | @Schema | @Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Displays the node cost label. -->
  <xsl:template match="s:RelOp" mode="NodeCostLabel">
    <xsl:variable name="EstimatedOperatorCost"><xsl:call-template name="EstimatedOperatorCost" /></xsl:variable>
    <xsl:variable name="TotalCost"><xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" /></xsl:variable>
    <div>Cost: <xsl:value-of select="format-number(number($EstimatedOperatorCost) div number($TotalCost), ''0%'')" /></div>
  </xsl:template>

  <!-- Dont show the node cost for statements. -->
  <xsl:template match="s:StmtSimple" mode="NodeCostLabel" />

  <!--
  ================================
  Tool tip detail sections
  ================================
  The following section contains templates used for writing the detail sections at the bottom of the tool tip,
  for example listing outputs, or information about the object to which an operator applies.
  -->

  <xsl:template match="*/s:Object" mode="ToolTipDetails">
    <!-- TODO: Make sure this works all the time -->
    <div class="qp-bold">Object</div>
    <div><xsl:apply-templates select="." mode="ObjectName" /></div>
  </xsl:template>

  <xsl:template match="s:SetPredicate[s:ScalarOperator/@ScalarString]" mode="ToolTipDetails">
    <div class="qp-bold">Predicate</div>
    <div><xsl:value-of select="s:ScalarOperator/@ScalarString" /></div>
  </xsl:template>

  <xsl:template match="s:OutputList[count(s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Output List</div>
    <xsl:for-each select="s:ColumnReference">
      <div><xsl:apply-templates select="." mode="ObjectName" /></div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="s:NestedLoops/s:OuterReferences[count(s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Outer References</div>
    <xsl:for-each select="s:ColumnReference">
      <div><xsl:apply-templates select="." mode="ObjectName" /></div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="@StatementText" mode="ToolTipDetails">
    <div class="qp-bold">Statement</div>
    <div><xsl:value-of select="." /></div>
  </xsl:template>

  <xsl:template match="s:Sort/s:OrderBy[count(s:OrderByColumn/s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Order By</div>
    <xsl:for-each select="s:OrderByColumn">
      <div>
        <xsl:apply-templates select="s:ColumnReference" mode="ObjectName" />
        <xsl:choose>
          <xsl:when test="@Ascending = 1"> Ascending</xsl:when>
          <xsl:otherwise> Descending</xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:for-each>
  </xsl:template>

  <!-- TODO: Seek Predicates -->

  <!--
  ================================
  Node icons
  ================================
  The following templates determine what icon should be shown for a given node
  -->

  <!-- Use the logical operation to determine the icon for the "Parallelism" operators. -->
  <xsl:template match="s:RelOp[@PhysicalOp = ''Parallelism'']" mode="NodeIcon" priority="1">
    <xsl:element name="div">
      <xsl:attribute name="class">qp-icon-<xsl:value-of select="translate(@LogicalOp, '' '', '''')" /></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Use the physical operation to determine icon if it is present. -->
  <xsl:template match="*[@PhysicalOp]" mode="NodeIcon">
    <xsl:element name="div">
      <xsl:attribute name="class">qp-icon-<xsl:value-of select="translate(@PhysicalOp, '' '', '''')" /></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Matches all statements. -->
  <xsl:template match="s:StmtSimple" mode="NodeIcon">
    <div class="qp-icon-Statement"></div>
  </xsl:template>

  <!-- Fallback template - show the Bitmap icon. -->
  <xsl:template match="*" mode="NodeIcon">
    <div class="qp-icon-Catchall"></div>
  </xsl:template>

  <!--
  ================================
  Node labels
  ================================
  The following section contains templates used to determine the first (main) label for a node.
  -->

  <xsl:template match="s:RelOp" mode="NodeLabel">
    <div><xsl:value-of select="@PhysicalOp" /></div>
  </xsl:template>

  <xsl:template match="s:StmtSimple" mode="NodeLabel">
    <div><xsl:value-of select="@StatementType" /></div>
  </xsl:template>

  <!--
  ================================
  Node alternate labels
  ================================
  The following section contains templates used to determine the second label to be displayed for a node.
  -->

  <!-- Display the object for any node that has one -->
  <xsl:template match="*[*/s:Object]" mode="NodeLabel2">
    <xsl:variable name="ObjectName">
      <xsl:apply-templates select="*/s:Object" mode="ObjectName">
        <xsl:with-param name="ExcludeDatabaseName" select="true()" />
      </xsl:apply-templates>
    </xsl:variable>
    <div>
      <xsl:value-of select="substring($ObjectName, 0, 36)" />
      <xsl:if test="string-length($ObjectName) >= 36">…</xsl:if>
    </div>
  </xsl:template>

  <!-- Display the logical operation for any node where it is not the same as the physical operation. -->
  <xsl:template match="s:RelOp[@LogicalOp != @PhysicalOp]" mode="NodeLabel2">
    <div>(<xsl:value-of select="@LogicalOp" />)</div>
  </xsl:template>

  <!-- Disable the default template -->
  <xsl:template match="*" mode="NodeLabel2" />

  <!--
  ================================
  Tool tip descriptions
  ================================
  The following section contains templates used for writing the description shown in the tool tip.
  -->

  <xsl:template match="*[@PhysicalOp = ''Table Insert'']" mode="ToolTipDescription">Insert input rows into the table specified in Argument field.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Compute Scalar'']" mode="ToolTipDescription">Compute new values from existing values in a row.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Sort'']" mode="ToolTipDescription">Sort the input.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Clustered Index Scan'']" mode="ToolTipDescription">Scanning a clustered index, entirely or only a range.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Stream Aggregate'']" mode="ToolTipDescription">Compute summary values for groups of rows in a suitably sorted stream.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Hash Match'']" mode="ToolTipDescription">Use each row from the top input to build a hash table, and each row from the bottom input to probe into the hash table, outputting all matching rows.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Bitmap'']" mode="ToolTipDescription">Bitmap.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Clustered Index Seek'']" mode="ToolTipDescription">Scanning a particular range of rows from a clustered index.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Index Seek'']" mode="ToolTipDescription">Scan a particular range of rows from a nonclustered index.</xsl:template>

  <xsl:template match="*[@PhysicalOp = ''Parallelism'' and @LogicalOp=''Repartition Streams'']" mode="ToolTipDescription">Repartition Streams.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Parallelism'']" mode="ToolTipDescription">An operation involving parallelism.</xsl:template>

  <xsl:template match="*[s:TableScan]" mode="ToolTipDescription">Scan rows from a table.</xsl:template>
  <xsl:template match="*[s:NestedLoops]" mode="ToolTipDescription">For each row in the top (outer) input, scan the bottom (inner) input, and output matching rows.</xsl:template>
  <xsl:template match="*[s:Top]" mode="ToolTipDescription">Select the first few rows based on a sort order.</xsl:template>

  <!--
  ================================
  Number handling
  ================================
  The following section contains templates used for handling numbers (scientific notation, rounding etc...)
  -->

  <!-- Outputs a number rounded to 7 decimal places - to be used for displaying all numbers.
  This template accepts numbers in scientific notation. -->
  <xsl:template name="round">
    <xsl:param name="value" select="0" />
    <xsl:variable name="number">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="$value" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="round(number($number) * 10000000) div 10000000" />
  </xsl:template>

  <!-- Template for handling of scientific numbers
  See: http://www.orm-designer.com/article/xslt-convert-scientific-notation-to-decimal-number -->
  <xsl:variable name="max-exp">
    <xsl:value-of select="''0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000''" />
  </xsl:variable>

  <xsl:template name="convertSciToNumString">
    <xsl:param name="inputVal" select="0" />

    <xsl:variable name="numInput">
      <xsl:value-of select="translate(string($inputVal),''e'',''E'')" />
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="number($numInput) = $numInput">
        <xsl:value-of select="$numInput" />
      </xsl:when>
      <xsl:otherwise>
        <!-- ==== Mantisa ==== -->
        <xsl:variable name="numMantisa">
          <xsl:value-of select="number(substring-before($numInput,''E''))" />
        </xsl:variable>

        <!-- ==== Exponent ==== -->
        <xsl:variable name="numExponent">
          <xsl:choose>
            <xsl:when test="contains($numInput,''E+'')">
              <xsl:value-of select="substring-after($numInput,''E+'')" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-after($numInput,''E'')" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- ==== Coefficient ==== -->
        <xsl:variable name="numCoefficient">
          <xsl:choose>
            <xsl:when test="$numExponent > 0">
              <xsl:text>1</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, number($numExponent))" />
            </xsl:when>
            <xsl:when test="$numExponent &lt; 0">
              <xsl:text>0.</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, -number($numExponent)-1)" />
              <xsl:text>1</xsl:text>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="number($numCoefficient) * number($numMantisa)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
', 'host', '//*[@StatementType="COMMIT TRANSACTION"]', 0, 'SELECT schema_name FROM (SELECT name as [schema_name] FROM master..sysdatabases) tmp');
INSERT INTO db_types VALUES (18, 'MS SQL Server 2017', 'SQL Server', 'CREATE DATABASE db_#databaseName#;
GO

ALTER DATABASE db_#databaseName# SET COMPATIBILITY_LEVEL = 140;
GO

USE db_#databaseName#;
GO

CREATE LOGIN user_#databaseName#
WITH PASSWORD = ''#databaseName#'', CHECK_POLICY = OFF;
GO

CREATE USER user_#databaseName#;
GO

GRANT
CREATE TABLE,
CREATE TYPE,
CREATE VIEW,
CREATE PROCEDURE,
CREATE FUNCTION,
CREATE FULLTEXT CATALOG,
EXECUTE,
DELETE,
INSERT,
REFERENCES,
SELECT,
SHOWPLAN,
UPDATE
TO user_#databaseName#;
GO



ALTER LOGIN user_#databaseName# WITH DEFAULT_DATABASE=db_#databaseName#;
GO

GRANT ALTER ON SCHEMA::dbo TO user_#databaseName#;
GO

-- Eval-SQL support:
sp_configure ''clr enabled'', 1;
GO
RECONFIGURE;
GO

CREATE ASSEMBLY [#databaseName#.Z.Expressions.Compiler] AUTHORIZATION [dbo] FROM ''/tmp/z_expressions_compiler.so'' WITH PERMISSION_SET = SAFE;

CREATE ASSEMBLY [#databaseName#.Z.Expressions.SqlServer.Eval] AUTHORIZATION [dbo] FROM ''/tmp/z_expressions_sqlserver_eval.so'' WITH PERMISSION_SET = SAFE;

CREATE TYPE [dbo].[SQLNET] EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET];

EXEC(''CREATE PROCEDURE [SQLNET_EvalResultSet] @sqlnet [SQLNET] AS EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET].[SQLNET_EvalResultSet]'')
EXEC(''CREATE FUNCTION [dbo].[SQLNET_EvalTVF_1] (@sqlnet [dbo].[SQLNET]) RETURNS TABLE ([Value_1] SQL_VARIANT NULL) AS EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET].[SQLNET_EvalTVF_1]'')
EXEC(''CREATE FUNCTION [dbo].[SQLNET_EvalTVF_2] (@sqlnet [dbo].[SQLNET]) RETURNS TABLE ([Value_1] SQL_VARIANT NULL, [Value_2] SQL_VARIANT NULL) AS EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET].[SQLNET_EvalTVF_2]'')
EXEC(''CREATE FUNCTION [dbo].[SQLNET_EvalTVF_3] (@sqlnet [dbo].[SQLNET]) RETURNS TABLE ([Value_1] SQL_VARIANT NULL, [Value_2] SQL_VARIANT NULL, [Value_3] SQL_VARIANT NULL) AS EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET].[SQLNET_EvalTVF_3]'')
EXEC(''CREATE FUNCTION [dbo].[SQLNET_EvalTVF_4] (@sqlnet [dbo].[SQLNET]) RETURNS TABLE ([Value_1] SQL_VARIANT NULL, [Value_2] SQL_VARIANT NULL, [Value_3] SQL_VARIANT NULL, [Value_4] SQL_VARIANT NULL) AS EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET].[SQLNET_EvalTVF_4]'')
EXEC(''CREATE FUNCTION [dbo].[SQLNET_EvalTVF_5] (@sqlnet [dbo].[SQLNET]) RETURNS TABLE ([Value_1] SQL_VARIANT NULL, [Value_2] SQL_VARIANT NULL, [Value_3] SQL_VARIANT NULL, [Value_4] SQL_VARIANT NULL, [Value_5] SQL_VARIANT NULL) AS EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET].[SQLNET_EvalTVF_5]'')
EXEC(''CREATE FUNCTION [dbo].[SQLNET_EvalTVF_String] (@sqlnet [dbo].[SQLNET]) RETURNS TABLE ( [Value_1] NVARCHAR (MAX) NULL) AS EXTERNAL NAME [#databaseName#.Z.Expressions.SqlServer.Eval].[Z.Expressions.SqlServer.Eval.SQLNET].[SQLNET_EvalTVF_String]'')

GO

use master;

', 'net.sourceforge.jtds.jdbc.Driver', 'exec dbo.clearDBUsers ''db_#databaseName#'';
GO
drop database db_#databaseName#;
GO
drop login user_#databaseName#;
', NULL, 'GO', NULL, '18/a7540/1', '
SET SHOWPLAN_XML ON;
GO
', '
GO
SET SHOWPLAN_XML OFF', '<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt"
  xmlns:s="http://schemas.microsoft.com/sqlserver/2004/07/showplan"
  exclude-result-prefixes="msxsl s xsl">
  <xsl:output method="html" indent="no" omit-xml-declaration="yes" />

  <!-- Disable built-in recursive processing templates -->
  <xsl:template match="*|/|text()|@*" mode="NodeLabel2" />
  <xsl:template match="*|/|text()|@*" mode="ToolTipDescription" />
  <xsl:template match="*|/|text()|@*" mode="ToolTipDetails" />

  <!-- Default template -->
  <xsl:template match="/">
    <xsl:apply-templates select="s:ShowPlanXML" />
  </xsl:template>

  <!-- Outermost div that contains all statement plans. -->
  <xsl:template match="s:ShowPlanXML">
    <div class="qp-root">
      <xsl:apply-templates select="s:BatchSequence/s:Batch/s:Statements/s:StmtSimple" />
    </div>
  </xsl:template>

  <!-- Matches a branch in the query plan (either an operation or a statement) -->
  <xsl:template match="s:RelOp|s:StmtSimple">
    <div class="qp-tr">
      <div>
        <div class="qp-node">
          <xsl:apply-templates select="." mode="NodeIcon" />
          <xsl:apply-templates select="." mode="NodeLabel" />
          <xsl:apply-templates select="." mode="NodeLabel2" />
          <xsl:apply-templates select="." mode="NodeCostLabel" />
          <xsl:call-template name="ToolTip" />
        </div>
      </div>
      <div><xsl:apply-templates select="*/s:RelOp" /></div>
    </div>
  </xsl:template>

  <!-- Writes the tool tip -->
  <xsl:template name="ToolTip">
    <div class="qp-tt">
      <div class="qp-tt-header"><xsl:value-of select="@PhysicalOp | @StatementType" /></div>
      <div><xsl:apply-templates select="." mode="ToolTipDescription" /></div>
      <xsl:call-template name="ToolTipGrid" />
      <xsl:apply-templates select="* | @* | */* | */@*" mode="ToolTipDetails" />
    </div>
  </xsl:template>

  <!-- Writes the grid of node properties to the tool tip -->
  <xsl:template name="ToolTipGrid">
    <table>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="s:QueryPlan/@CachedPlanSize" />
        <xsl:with-param name="Label">Cached plan size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(s:QueryPlan/@CachedPlanSize, '' B'')" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Physical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@PhysicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Logical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@LogicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Actual Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualRows" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateIO" />
        <xsl:with-param name="Label">Estimated I/O Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateIO" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateCPU" />
        <xsl:with-param name="Label">Estimated CPU Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateCPU" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <!-- TODO: Estimated Number of Executions -->
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Number of Executions</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualExecutions" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Degree of Parallelism</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@DegreeOfParallelism" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Memory Grant</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@MemoryGrant" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateIO | @EstimateCPU" />
        <xsl:with-param name="Label">Estimated Operator Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:variable name="EstimatedOperatorCost">
            <xsl:call-template name="EstimatedOperatorCost" />
          </xsl:variable>
          <xsl:variable name="TotalCost">
            <xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" />
          </xsl:variable>

          <xsl:call-template name="round">
            <xsl:with-param name="value" select="$EstimatedOperatorCost" />
          </xsl:call-template>
          (<xsl:value-of select="format-number(number($EstimatedOperatorCost) div number($TotalCost), ''0%'')" />)
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
        <xsl:with-param name="Label">Estimated Subtree Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Estimated Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="@StatementEstRows | @EstimateRows" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@AvgRowSize" />
        <xsl:with-param name="Label">Estimated Row Size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(@AvgRowSize, '' B'')" />
      </xsl:call-template>
      <!-- TODO: Actual Rebinds
           TODO: Actual Rewinds -->
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="s:IndexScan/@Ordered" />
        <xsl:with-param name="Label">Ordered</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:choose>
            <xsl:when test="s:IndexScan/@Ordered = 1">True</xsl:when>
            <xsl:otherwise>False</xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Node ID</xsl:with-param>
        <xsl:with-param name="Value" select="@NodeId" />
      </xsl:call-template>
    </table>
  </xsl:template>

  <!-- Calculates the estimated operator cost. -->
  <xsl:template name="EstimatedOperatorCost">
    <xsl:variable name="EstimateIO">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateIO" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="EstimateCPU">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateCPU" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="number($EstimateIO) + number($EstimateCPU)" />
  </xsl:template>

  <!-- Renders a row in the tool tip details table. -->
  <xsl:template name="ToolTipRow">
    <xsl:param name="Label" />
    <xsl:param name="Value" />
    <xsl:param name="Condition" select="$Value" />
    <xsl:if test="$Condition">
      <tr>
        <th><xsl:value-of select="$Label" /></th>
        <td><xsl:value-of select="$Value" /></td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- Prints the name of an object. -->
  <xsl:template match="s:Object | s:ColumnReference" mode="ObjectName">
    <xsl:param name="ExcludeDatabaseName" select="false()" />
    <xsl:choose>
      <xsl:when test="$ExcludeDatabaseName">
        <xsl:for-each select="@Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="@Database | @Schema | @Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Displays the node cost label. -->
  <xsl:template match="s:RelOp" mode="NodeCostLabel">
    <xsl:variable name="EstimatedOperatorCost"><xsl:call-template name="EstimatedOperatorCost" /></xsl:variable>
    <xsl:variable name="TotalCost"><xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" /></xsl:variable>
    <div>Cost: <xsl:value-of select="format-number(number($EstimatedOperatorCost) div number($TotalCost), ''0%'')" /></div>
  </xsl:template>

  <!-- Dont show the node cost for statements. -->
  <xsl:template match="s:StmtSimple" mode="NodeCostLabel" />

  <!--
  ================================
  Tool tip detail sections
  ================================
  The following section contains templates used for writing the detail sections at the bottom of the tool tip,
  for example listing outputs, or information about the object to which an operator applies.
  -->

  <xsl:template match="*/s:Object" mode="ToolTipDetails">
    <!-- TODO: Make sure this works all the time -->
    <div class="qp-bold">Object</div>
    <div><xsl:apply-templates select="." mode="ObjectName" /></div>
  </xsl:template>

  <xsl:template match="s:SetPredicate[s:ScalarOperator/@ScalarString]" mode="ToolTipDetails">
    <div class="qp-bold">Predicate</div>
    <div><xsl:value-of select="s:ScalarOperator/@ScalarString" /></div>
  </xsl:template>

  <xsl:template match="s:OutputList[count(s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Output List</div>
    <xsl:for-each select="s:ColumnReference">
      <div><xsl:apply-templates select="." mode="ObjectName" /></div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="s:NestedLoops/s:OuterReferences[count(s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Outer References</div>
    <xsl:for-each select="s:ColumnReference">
      <div><xsl:apply-templates select="." mode="ObjectName" /></div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="@StatementText" mode="ToolTipDetails">
    <div class="qp-bold">Statement</div>
    <div><xsl:value-of select="." /></div>
  </xsl:template>

  <xsl:template match="s:Sort/s:OrderBy[count(s:OrderByColumn/s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Order By</div>
    <xsl:for-each select="s:OrderByColumn">
      <div>
        <xsl:apply-templates select="s:ColumnReference" mode="ObjectName" />
        <xsl:choose>
          <xsl:when test="@Ascending = 1"> Ascending</xsl:when>
          <xsl:otherwise> Descending</xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:for-each>
  </xsl:template>

  <!-- TODO: Seek Predicates -->

  <!--
  ================================
  Node icons
  ================================
  The following templates determine what icon should be shown for a given node
  -->

  <!-- Use the logical operation to determine the icon for the "Parallelism" operators. -->
  <xsl:template match="s:RelOp[@PhysicalOp = ''Parallelism'']" mode="NodeIcon" priority="1">
    <xsl:element name="div">
      <xsl:attribute name="class">qp-icon-<xsl:value-of select="translate(@LogicalOp, '' '', '''')" /></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Use the physical operation to determine icon if it is present. -->
  <xsl:template match="*[@PhysicalOp]" mode="NodeIcon">
    <xsl:element name="div">
      <xsl:attribute name="class">qp-icon-<xsl:value-of select="translate(@PhysicalOp, '' '', '''')" /></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Matches all statements. -->
  <xsl:template match="s:StmtSimple" mode="NodeIcon">
    <div class="qp-icon-Statement"></div>
  </xsl:template>

  <!-- Fallback template - show the Bitmap icon. -->
  <xsl:template match="*" mode="NodeIcon">
    <div class="qp-icon-Catchall"></div>
  </xsl:template>

  <!--
  ================================
  Node labels
  ================================
  The following section contains templates used to determine the first (main) label for a node.
  -->

  <xsl:template match="s:RelOp" mode="NodeLabel">
    <div><xsl:value-of select="@PhysicalOp" /></div>
  </xsl:template>

  <xsl:template match="s:StmtSimple" mode="NodeLabel">
    <div><xsl:value-of select="@StatementType" /></div>
  </xsl:template>

  <!--
  ================================
  Node alternate labels
  ================================
  The following section contains templates used to determine the second label to be displayed for a node.
  -->

  <!-- Display the object for any node that has one -->
  <xsl:template match="*[*/s:Object]" mode="NodeLabel2">
    <xsl:variable name="ObjectName">
      <xsl:apply-templates select="*/s:Object" mode="ObjectName">
        <xsl:with-param name="ExcludeDatabaseName" select="true()" />
      </xsl:apply-templates>
    </xsl:variable>
    <div>
      <xsl:value-of select="substring($ObjectName, 0, 36)" />
      <xsl:if test="string-length($ObjectName) >= 36">…</xsl:if>
    </div>
  </xsl:template>

  <!-- Display the logical operation for any node where it is not the same as the physical operation. -->
  <xsl:template match="s:RelOp[@LogicalOp != @PhysicalOp]" mode="NodeLabel2">
    <div>(<xsl:value-of select="@LogicalOp" />)</div>
  </xsl:template>

  <!-- Disable the default template -->
  <xsl:template match="*" mode="NodeLabel2" />

  <!--
  ================================
  Tool tip descriptions
  ================================
  The following section contains templates used for writing the description shown in the tool tip.
  -->

  <xsl:template match="*[@PhysicalOp = ''Table Insert'']" mode="ToolTipDescription">Insert input rows into the table specified in Argument field.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Compute Scalar'']" mode="ToolTipDescription">Compute new values from existing values in a row.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Sort'']" mode="ToolTipDescription">Sort the input.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Clustered Index Scan'']" mode="ToolTipDescription">Scanning a clustered index, entirely or only a range.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Stream Aggregate'']" mode="ToolTipDescription">Compute summary values for groups of rows in a suitably sorted stream.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Hash Match'']" mode="ToolTipDescription">Use each row from the top input to build a hash table, and each row from the bottom input to probe into the hash table, outputting all matching rows.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Bitmap'']" mode="ToolTipDescription">Bitmap.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Clustered Index Seek'']" mode="ToolTipDescription">Scanning a particular range of rows from a clustered index.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Index Seek'']" mode="ToolTipDescription">Scan a particular range of rows from a nonclustered index.</xsl:template>

  <xsl:template match="*[@PhysicalOp = ''Parallelism'' and @LogicalOp=''Repartition Streams'']" mode="ToolTipDescription">Repartition Streams.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Parallelism'']" mode="ToolTipDescription">An operation involving parallelism.</xsl:template>

  <xsl:template match="*[s:TableScan]" mode="ToolTipDescription">Scan rows from a table.</xsl:template>
  <xsl:template match="*[s:NestedLoops]" mode="ToolTipDescription">For each row in the top (outer) input, scan the bottom (inner) input, and output matching rows.</xsl:template>
  <xsl:template match="*[s:Top]" mode="ToolTipDescription">Select the first few rows based on a sort order.</xsl:template>

  <!--
  ================================
  Number handling
  ================================
  The following section contains templates used for handling numbers (scientific notation, rounding etc...)
  -->

  <!-- Outputs a number rounded to 7 decimal places - to be used for displaying all numbers.
  This template accepts numbers in scientific notation. -->
  <xsl:template name="round">
    <xsl:param name="value" select="0" />
    <xsl:variable name="number">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="$value" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="round(number($number) * 10000000) div 10000000" />
  </xsl:template>

  <!-- Template for handling of scientific numbers
  See: http://www.orm-designer.com/article/xslt-convert-scientific-notation-to-decimal-number -->
  <xsl:variable name="max-exp">
    <xsl:value-of select="''0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000''" />
  </xsl:variable>

  <xsl:template name="convertSciToNumString">
    <xsl:param name="inputVal" select="0" />

    <xsl:variable name="numInput">
      <xsl:value-of select="translate(string($inputVal),''e'',''E'')" />
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="number($numInput) = $numInput">
        <xsl:value-of select="$numInput" />
      </xsl:when>
      <xsl:otherwise>
        <!-- ==== Mantisa ==== -->
        <xsl:variable name="numMantisa">
          <xsl:value-of select="number(substring-before($numInput,''E''))" />
        </xsl:variable>

        <!-- ==== Exponent ==== -->
        <xsl:variable name="numExponent">
          <xsl:choose>
            <xsl:when test="contains($numInput,''E+'')">
              <xsl:value-of select="substring-after($numInput,''E+'')" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-after($numInput,''E'')" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- ==== Coefficient ==== -->
        <xsl:variable name="numCoefficient">
          <xsl:choose>
            <xsl:when test="$numExponent > 0">
              <xsl:text>1</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, number($numExponent))" />
            </xsl:when>
            <xsl:when test="$numExponent &lt; 0">
              <xsl:text>0.</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, -number($numExponent)-1)" />
              <xsl:text>1</xsl:text>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="number($numCoefficient) * number($numMantisa)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
', 'host', '//*[@StatementType="COMMIT TRANSACTION"]', 1, 'SELECT schema_name FROM (SELECT name as [schema_name] FROM master..sysdatabases) tmp');
INSERT INTO db_types VALUES (3, 'MS SQL Server 2008', 'SQL Server', 'CREATE DATABASE db_#databaseName#;
GO

ALTER DATABASE db_#databaseName# SET COMPATIBILITY_LEVEL = 100;
GO

USE db_#databaseName#;
GO

CREATE LOGIN user_#databaseName#
WITH PASSWORD = ''#databaseName#'', CHECK_POLICY = OFF;
GO

CREATE USER user_#databaseName#;
GO

GRANT
CREATE TABLE,
CREATE TYPE,
CREATE VIEW,
CREATE PROCEDURE,
CREATE FUNCTION,
CREATE FULLTEXT CATALOG,
EXECUTE,
DELETE,
INSERT,
REFERENCES,
SELECT,
SHOWPLAN,
UPDATE
TO user_#databaseName#;
GO



ALTER LOGIN user_#databaseName# WITH DEFAULT_DATABASE=db_#databaseName#;
GO

GRANT ALTER ON SCHEMA::dbo TO user_#databaseName#;
GO

use master;

', 'net.sourceforge.jtds.jdbc.Driver', 'exec dbo.clearDBUsers ''db_#databaseName#'';
GO
drop database db_#databaseName#;
GO
drop login user_#databaseName#;
', NULL, 'GO', 'SQL Server supports multiple statements in a batch separated by semicolons. Separate statement batches with a line consisting of a single GO command, as needed.', '3/b6640/1', '
SET SHOWPLAN_XML ON;
GO
', '
GO
SET SHOWPLAN_XML OFF', '
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt"
  xmlns:s="http://schemas.microsoft.com/sqlserver/2004/07/showplan"
  exclude-result-prefixes="msxsl s xsl">
  <xsl:output method="html" indent="no" omit-xml-declaration="yes" />

  <!-- Disable built-in recursive processing templates -->
  <xsl:template match="*|/|text()|@*" mode="NodeLabel2" />
  <xsl:template match="*|/|text()|@*" mode="ToolTipDescription" />
  <xsl:template match="*|/|text()|@*" mode="ToolTipDetails" />

  <!-- Default template -->
  <xsl:template match="/">
    <xsl:apply-templates select="s:ShowPlanXML" />
  </xsl:template>

  <!-- Outermost div that contains all statement plans. -->
  <xsl:template match="s:ShowPlanXML">
    <div class="qp-root">
      <xsl:apply-templates select="s:BatchSequence/s:Batch/s:Statements/s:StmtSimple" />
    </div>
  </xsl:template>

  <!-- Matches a branch in the query plan (either an operation or a statement) -->
  <xsl:template match="s:RelOp|s:StmtSimple">
    <div class="qp-tr">
      <div>
        <div class="qp-node">
          <xsl:apply-templates select="." mode="NodeIcon" />
          <xsl:apply-templates select="." mode="NodeLabel" />
          <xsl:apply-templates select="." mode="NodeLabel2" />
          <xsl:apply-templates select="." mode="NodeCostLabel" />
          <xsl:call-template name="ToolTip" />
        </div>
      </div>
      <div><xsl:apply-templates select="*/s:RelOp" /></div>
    </div>
  </xsl:template>

  <!-- Writes the tool tip -->
  <xsl:template name="ToolTip">
    <div class="qp-tt">
      <div class="qp-tt-header"><xsl:value-of select="@PhysicalOp | @StatementType" /></div>
      <div><xsl:apply-templates select="." mode="ToolTipDescription" /></div>
      <xsl:call-template name="ToolTipGrid" />
      <xsl:apply-templates select="* | @* | */* | */@*" mode="ToolTipDetails" />
    </div>
  </xsl:template>

  <!-- Writes the grid of node properties to the tool tip -->
  <xsl:template name="ToolTipGrid">
    <table>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="s:QueryPlan/@CachedPlanSize" />
        <xsl:with-param name="Label">Cached plan size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(s:QueryPlan/@CachedPlanSize, '' B'')" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Physical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@PhysicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Logical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@LogicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Actual Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualRows" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateIO" />
        <xsl:with-param name="Label">Estimated I/O Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateIO" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateCPU" />
        <xsl:with-param name="Label">Estimated CPU Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateCPU" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <!-- TODO: Estimated Number of Executions -->
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Number of Executions</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualExecutions" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Degree of Parallelism</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@DegreeOfParallelism" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Memory Grant</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@MemoryGrant" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@EstimateIO | @EstimateCPU" />
        <xsl:with-param name="Label">Estimated Operator Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:variable name="EstimatedOperatorCost">
            <xsl:call-template name="EstimatedOperatorCost" />
          </xsl:variable>
          <xsl:variable name="TotalCost">
            <xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" />
          </xsl:variable>

          <xsl:call-template name="round">
            <xsl:with-param name="value" select="$EstimatedOperatorCost" />
          </xsl:call-template>
          (<xsl:value-of select="format-number(number($EstimatedOperatorCost) div number($TotalCost), ''0%'')" />)
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
        <xsl:with-param name="Label">Estimated Subtree Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Estimated Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="@StatementEstRows | @EstimateRows" />
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="@AvgRowSize" />
        <xsl:with-param name="Label">Estimated Row Size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(@AvgRowSize, '' B'')" />
      </xsl:call-template>
      <!-- TODO: Actual Rebinds
           TODO: Actual Rewinds -->
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Condition" select="s:IndexScan/@Ordered" />
        <xsl:with-param name="Label">Ordered</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:choose>
            <xsl:when test="s:IndexScan/@Ordered = 1">True</xsl:when>
            <xsl:otherwise>False</xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ToolTipRow">
        <xsl:with-param name="Label">Node ID</xsl:with-param>
        <xsl:with-param name="Value" select="@NodeId" />
      </xsl:call-template>
    </table>
  </xsl:template>

  <!-- Calculates the estimated operator cost. -->
  <xsl:template name="EstimatedOperatorCost">
    <xsl:variable name="EstimateIO">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateIO" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="EstimateCPU">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateCPU" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="number($EstimateIO) + number($EstimateCPU)" />
  </xsl:template>

  <!-- Renders a row in the tool tip details table. -->
  <xsl:template name="ToolTipRow">
    <xsl:param name="Label" />
    <xsl:param name="Value" />
    <xsl:param name="Condition" select="$Value" />
    <xsl:if test="$Condition">
      <tr>
        <th><xsl:value-of select="$Label" /></th>
        <td><xsl:value-of select="$Value" /></td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- Prints the name of an object. -->
  <xsl:template match="s:Object | s:ColumnReference" mode="ObjectName">
    <xsl:param name="ExcludeDatabaseName" select="false()" />
    <xsl:choose>
      <xsl:when test="$ExcludeDatabaseName">
        <xsl:for-each select="@Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="@Database | @Schema | @Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Displays the node cost label. -->
  <xsl:template match="s:RelOp" mode="NodeCostLabel">
    <xsl:variable name="EstimatedOperatorCost"><xsl:call-template name="EstimatedOperatorCost" /></xsl:variable>
    <xsl:variable name="TotalCost"><xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" /></xsl:variable>
    <div>Cost: <xsl:value-of select="format-number(number($EstimatedOperatorCost) div number($TotalCost), ''0%'')" /></div>
  </xsl:template>

  <!-- Dont show the node cost for statements. -->
  <xsl:template match="s:StmtSimple" mode="NodeCostLabel" />

  <!--
  ================================
  Tool tip detail sections
  ================================
  The following section contains templates used for writing the detail sections at the bottom of the tool tip,
  for example listing outputs, or information about the object to which an operator applies.
  -->

  <xsl:template match="*/s:Object" mode="ToolTipDetails">
    <!-- TODO: Make sure this works all the time -->
    <div class="qp-bold">Object</div>
    <div><xsl:apply-templates select="." mode="ObjectName" /></div>
  </xsl:template>

  <xsl:template match="s:SetPredicate[s:ScalarOperator/@ScalarString]" mode="ToolTipDetails">
    <div class="qp-bold">Predicate</div>
    <div><xsl:value-of select="s:ScalarOperator/@ScalarString" /></div>
  </xsl:template>

  <xsl:template match="s:OutputList[count(s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Output List</div>
    <xsl:for-each select="s:ColumnReference">
      <div><xsl:apply-templates select="." mode="ObjectName" /></div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="s:NestedLoops/s:OuterReferences[count(s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Outer References</div>
    <xsl:for-each select="s:ColumnReference">
      <div><xsl:apply-templates select="." mode="ObjectName" /></div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="@StatementText" mode="ToolTipDetails">
    <div class="qp-bold">Statement</div>
    <div><xsl:value-of select="." /></div>
  </xsl:template>

  <xsl:template match="s:Sort/s:OrderBy[count(s:OrderByColumn/s:ColumnReference) > 0]" mode="ToolTipDetails">
    <div class="qp-bold">Order By</div>
    <xsl:for-each select="s:OrderByColumn">
      <div>
        <xsl:apply-templates select="s:ColumnReference" mode="ObjectName" />
        <xsl:choose>
          <xsl:when test="@Ascending = 1"> Ascending</xsl:when>
          <xsl:otherwise> Descending</xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:for-each>
  </xsl:template>

  <!-- TODO: Seek Predicates -->

  <!--
  ================================
  Node icons
  ================================
  The following templates determine what icon should be shown for a given node
  -->

  <!-- Use the logical operation to determine the icon for the "Parallelism" operators. -->
  <xsl:template match="s:RelOp[@PhysicalOp = ''Parallelism'']" mode="NodeIcon" priority="1">
    <xsl:element name="div">
      <xsl:attribute name="class">qp-icon-<xsl:value-of select="translate(@LogicalOp, '' '', '''')" /></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Use the physical operation to determine icon if it is present. -->
  <xsl:template match="*[@PhysicalOp]" mode="NodeIcon">
    <xsl:element name="div">
      <xsl:attribute name="class">qp-icon-<xsl:value-of select="translate(@PhysicalOp, '' '', '''')" /></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Matches all statements. -->
  <xsl:template match="s:StmtSimple" mode="NodeIcon">
    <div class="qp-icon-Statement"></div>
  </xsl:template>

  <!-- Fallback template - show the Bitmap icon. -->
  <xsl:template match="*" mode="NodeIcon">
    <div class="qp-icon-Catchall"></div>
  </xsl:template>

  <!--
  ================================
  Node labels
  ================================
  The following section contains templates used to determine the first (main) label for a node.
  -->

  <xsl:template match="s:RelOp" mode="NodeLabel">
    <div><xsl:value-of select="@PhysicalOp" /></div>
  </xsl:template>

  <xsl:template match="s:StmtSimple" mode="NodeLabel">
    <div><xsl:value-of select="@StatementType" /></div>
  </xsl:template>

  <!--
  ================================
  Node alternate labels
  ================================
  The following section contains templates used to determine the second label to be displayed for a node.
  -->

  <!-- Display the object for any node that has one -->
  <xsl:template match="*[*/s:Object]" mode="NodeLabel2">
    <xsl:variable name="ObjectName">
      <xsl:apply-templates select="*/s:Object" mode="ObjectName">
        <xsl:with-param name="ExcludeDatabaseName" select="true()" />
      </xsl:apply-templates>
    </xsl:variable>
    <div>
      <xsl:value-of select="substring($ObjectName, 0, 36)" />
      <xsl:if test="string-length($ObjectName) >= 36">…</xsl:if>
    </div>
  </xsl:template>

  <!-- Display the logical operation for any node where it is not the same as the physical operation. -->
  <xsl:template match="s:RelOp[@LogicalOp != @PhysicalOp]" mode="NodeLabel2">
    <div>(<xsl:value-of select="@LogicalOp" />)</div>
  </xsl:template>

  <!-- Disable the default template -->
  <xsl:template match="*" mode="NodeLabel2" />

  <!--
  ================================
  Tool tip descriptions
  ================================
  The following section contains templates used for writing the description shown in the tool tip.
  -->

  <xsl:template match="*[@PhysicalOp = ''Table Insert'']" mode="ToolTipDescription">Insert input rows into the table specified in Argument field.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Compute Scalar'']" mode="ToolTipDescription">Compute new values from existing values in a row.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Sort'']" mode="ToolTipDescription">Sort the input.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Clustered Index Scan'']" mode="ToolTipDescription">Scanning a clustered index, entirely or only a range.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Stream Aggregate'']" mode="ToolTipDescription">Compute summary values for groups of rows in a suitably sorted stream.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Hash Match'']" mode="ToolTipDescription">Use each row from the top input to build a hash table, and each row from the bottom input to probe into the hash table, outputting all matching rows.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Bitmap'']" mode="ToolTipDescription">Bitmap.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Clustered Index Seek'']" mode="ToolTipDescription">Scanning a particular range of rows from a clustered index.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Index Seek'']" mode="ToolTipDescription">Scan a particular range of rows from a nonclustered index.</xsl:template>

  <xsl:template match="*[@PhysicalOp = ''Parallelism'' and @LogicalOp=''Repartition Streams'']" mode="ToolTipDescription">Repartition Streams.</xsl:template>
  <xsl:template match="*[@PhysicalOp = ''Parallelism'']" mode="ToolTipDescription">An operation involving parallelism.</xsl:template>

  <xsl:template match="*[s:TableScan]" mode="ToolTipDescription">Scan rows from a table.</xsl:template>
  <xsl:template match="*[s:NestedLoops]" mode="ToolTipDescription">For each row in the top (outer) input, scan the bottom (inner) input, and output matching rows.</xsl:template>
  <xsl:template match="*[s:Top]" mode="ToolTipDescription">Select the first few rows based on a sort order.</xsl:template>

  <!--
  ================================
  Number handling
  ================================
  The following section contains templates used for handling numbers (scientific notation, rounding etc...)
  -->

  <!-- Outputs a number rounded to 7 decimal places - to be used for displaying all numbers.
  This template accepts numbers in scientific notation. -->
  <xsl:template name="round">
    <xsl:param name="value" select="0" />
    <xsl:variable name="number">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="$value" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="round(number($number) * 10000000) div 10000000" />
  </xsl:template>

  <!-- Template for handling of scientific numbers
  See: http://www.orm-designer.com/article/xslt-convert-scientific-notation-to-decimal-number -->
  <xsl:variable name="max-exp">
    <xsl:value-of select="''0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000''" />
  </xsl:variable>

  <xsl:template name="convertSciToNumString">
    <xsl:param name="inputVal" select="0" />

    <xsl:variable name="numInput">
      <xsl:value-of select="translate(string($inputVal),''e'',''E'')" />
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="number($numInput) = $numInput">
        <xsl:value-of select="$numInput" />
      </xsl:when>
      <xsl:otherwise>
        <!-- ==== Mantisa ==== -->
        <xsl:variable name="numMantisa">
          <xsl:value-of select="number(substring-before($numInput,''E''))" />
        </xsl:variable>

        <!-- ==== Exponent ==== -->
        <xsl:variable name="numExponent">
          <xsl:choose>
            <xsl:when test="contains($numInput,''E+'')">
              <xsl:value-of select="substring-after($numInput,''E+'')" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-after($numInput,''E'')" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- ==== Coefficient ==== -->
        <xsl:variable name="numCoefficient">
          <xsl:choose>
            <xsl:when test="$numExponent > 0">
              <xsl:text>1</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, number($numExponent))" />
            </xsl:when>
            <xsl:when test="$numExponent &lt; 0">
              <xsl:text>0.</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, -number($numExponent)-1)" />
              <xsl:text>1</xsl:text>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="number($numCoefficient) * number($numMantisa)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
', 'host', '//*[@StatementType="COMMIT TRANSACTION"]', 0, 'SELECT schema_name FROM (SELECT name as [schema_name] FROM master..sysdatabases) tmp');


--
-- Name: db_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('db_types_id_seq', 18, true);


--
-- Data for Name: schema_defs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO schema_defs VALUES (2, 7, '44b90', '2014-05-11 05:28:27.178', '-- this version is using your browser''s built-in SQLite
CREATE TABLE supportContacts
	(
     id integer primary key,
     type varchar(20),
     details varchar(30)
    );

INSERT INTO supportContacts
(id, type, details)
VALUES
(1, ''Email'', ''admin@sqlfiddle.com'');

INSERT INTO supportContacts
(id, type, details)
VALUES
(2, ''Twitter'', ''@sqlfiddle'');', NULL, '44b900020923ae6d1b517286d9440347', ';', NULL, NULL, 1);
INSERT INTO schema_defs VALUES (3, 5, 'b5362', '2014-05-11 05:30:43.667', 'CREATE TABLE supportContacts
	(
     id integer primary key,
     type varchar(20),
     details varchar(30)
    );

INSERT INTO supportContacts
(id, type, details)
VALUES
(1, ''Email'', ''admin@sqlfiddle.com'');

INSERT INTO supportContacts
(id, type, details)
VALUES
(2, ''Twitter'', ''@sqlfiddle'');', NULL, 'b5362d09c5119808a6c7409fd00a64b7', ';', NULL, NULL, 1);
INSERT INTO schema_defs VALUES (38, 4, 'c0be1', '2014-12-07 21:32:48.736', '-- table for our logging
create table log_table
( message varchar2(200)
)
//

-- create package spec
create or replace package pkg_test
is
    -- define one public procedure
    procedure do;
end;
//

-- create package body
create or replace package body pkg_test
is
    -- private log procedure
    procedure log(p_message in varchar)
    is
    begin
        insert into log_table(message) values (p_message);
    end;

    -- private function to return twice the input
    function double(p_number in number)
    return number
    is
    begin
        return 2 * p_number;
    end;

    -- public procedure that does. :)
    procedure do
    is
    begin
        log(''2 * 12 = '' || double(12));
    end;

end;
//', NULL, 'c0be1c42165643ccdd365afbd01e3cf0', '//', NULL, '[{"columns":[{"type":"VARCHAR2(200)","name":"MESSAGE"}],"table_type":"TABLE","table_name":"LOG_TABLE"}]', 1);
INSERT INTO schema_defs VALUES (40, 2, 'dcb16', '2014-05-11 05:15:24.462', '

CREATE TABLE ForgeRock
	(`id` int, `productName` varchar(7), `description` varchar(55))
;

INSERT INTO ForgeRock
	(`id`, `productName`, `description`)
VALUES
	(1, ''OpenIDM'', ''Platform for building enterprise provisioning solutions''),
	(2, ''OpenAM'', ''Full-featured access management''),
	(3, ''OpenDJ'', ''Robust LDAP server for Java'')
;
', NULL, 'dcb16f2d44703cf35623e5c8650f070e', ';', NULL, '[{"columns":[{"type":"INT(10)","name":"id"},{"type":"VARCHAR(7)","name":"productName"},{"type":"VARCHAR(55)","name":"description"}],"table_type":"TABLE","table_name":"forgerock"}]', 1);
INSERT INTO schema_defs VALUES (1, 15, '35773', '2014-05-11 05:24:44.982', 'create table jsonData (
    id serial primary key,
    data json
);

insert into jsonData (data) values (
''{
  "a": 1,
  "b": 2,
  "c": ["dog","cat","mouse"],
  "d": {
    "x": true
  }
 }
''::json),
(
''{
  "a": 20,
  "b": 40,
  "c": ["fish","cat","rat","hamster"],
  "d": {
    "x": false
  }
 }
''::json);', NULL, '357738cadc59cd69eeb683e8e0f8fd8d', ';', NULL, '[{"columns":[{"type":"serial(10)","name":"id"},{"type":"json(2147483647)","name":"data"}],"table_type":"TABLE","table_name":"jsondata"}]', 1);
INSERT INTO schema_defs VALUES (4, 9, 'dcb16', '2014-05-11 05:15:24.462', '

CREATE TABLE ForgeRock
	(`id` int, `productName` varchar(7), `description` varchar(55))
;

INSERT INTO ForgeRock
	(`id`, `productName`, `description`)
VALUES
	(1, ''OpenIDM'', ''Platform for building enterprise provisioning solutions''),
	(2, ''OpenAM'', ''Full-featured access management''),
	(3, ''OpenDJ'', ''Robust LDAP server for Java'')
;
', NULL, 'dcb16f2d44703cf35623e5c8650f070e', ';', NULL, '[{"columns":[{"type":"INT(10)","name":"id"},{"type":"VARCHAR(7)","name":"productName"},{"type":"VARCHAR(55)","name":"description"}],"table_type":"TABLE","table_name":"forgerock"}]', 1);
INSERT INTO schema_defs VALUES (42, 16, '69b4b', '2017-06-16 02:32:16.105804', 'create table jsonData (
    id serial primary key,
    data jsonb
);

insert into jsonData (data) values (
''{
  "a": 1,
  "b": 2,
  "c": ["dog","cat","mouse"],
  "d": {
    "x": true
  }
 }
''::json),
(
''{
  "a": 20,
  "b": 40,
  "c": ["fish","cat","rat","hamster"],
  "d": {
    "x": false
  }
 }
''::json);', NULL, '69b4bf28985c2697362832f739bbfc0d', ';', NULL, '[{"table_name":"jsondata","table_type":"TABLE","columns":[{"name":"id","type":"serial(10)"},{"name":"data","type":"jsonb(2147483647)"}]}]', 1);
INSERT INTO schema_defs VALUES (44, 18, 'a7540', '2017-12-27 00:32:35.962829', '

CREATE TABLE ForgeRock
    ([productName] varchar(13), [description] varchar(57))
;

INSERT INTO ForgeRock
    ([productName], [description])
VALUES
    (''OpenIDM'', ''Platform for building enterprise provisioning solutions''),
    (''OpenAM'', ''Full-featured access management''),
    (''OpenDJ'', ''Robust LDAP server for Java'')
;
', NULL, 'a7540325c43a47db91002a51023b5ec2', ';', NULL, '[{"table_name":"ForgeRock","table_type":"TABLE","columns":[{"name":"productName","type":"varchar(13)"},{"name":"description","type":"varchar(57)"}]}]', 1);
INSERT INTO schema_defs VALUES (39, 6, 'a7540', '2014-12-07 21:53:17.243', '

CREATE TABLE ForgeRock
    ([productName] varchar(13), [description] varchar(57))
;

INSERT INTO ForgeRock
    ([productName], [description])
VALUES
    (''OpenIDM'', ''Platform for building enterprise provisioning solutions''),
    (''OpenAM'', ''Full-featured access management''),
    (''OpenDJ'', ''Robust LDAP server for Java'')
;
', NULL, 'a7540325c43a47db91002a51023b5ec2', ';', NULL, '[{"columns":[{"type":"varchar(13)","name":"productName"},{"type":"varchar(57)","name":"description"}],"table_type":"TABLE","table_name":"ForgeRock"}]', 1);
INSERT INTO schema_defs VALUES (46, 3, 'b6640', '2017-12-27 04:22:35.234119', '

CREATE TABLE ForgeRock
    ([productName] varchar(13), [description] varchar(57))
;

INSERT INTO ForgeRock
    ([productName], [description])
VALUES
    (''OpenIDM'', ''Platform for building enterprise provisioning solutions''),
    (''OpenAM'', ''Full-featured access management''),
    (''OpenDJ'', ''Robust LDAP server for Java'')
;
', NULL, 'b66403fcdc5e43888577eb20a469538e', ';', NULL, '[{"table_name":"ForgeRock","table_type":"TABLE","columns":[{"name":"productName","type":"varchar(13)"},{"name":"description","type":"varchar(57)"}]}]', 1);


--
-- Data for Name: queries; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO queries VALUES (4, '-- visit ForgeRock.com for details on the Open Identity Stack
-- sqlfiddle.com is built with OpenIDM

SELECT
  productName,
  description
FROM
  ForgeRock', '486c85215008690438a43ad3fab9b0f7', 1, ';', NULL);
INSERT INTO queries VALUES (1, 'SELECT
  json_extract_path_text(data, ''b'') as b,
  json_array_length(data->''c'') as numAnimals
FROM
  jsonData
WHERE
  json_extract_path_text(data->''d'', ''x'') = ''true''
', 'afe7d9b310445307acdfadba54e5c4dd', 1, ';', NULL);
INSERT INTO queries VALUES (2, 'select * from supportContacts
order by id desc', '7f9a9b537f2a77076a5be8b98c5d1ae3', 1, ';', NULL);
INSERT INTO queries VALUES (3, 'select * from supportContacts
order by id desc', '7f9a9b537f2a77076a5be8b98c5d1ae3', 1, ';', NULL);
INSERT INTO queries VALUES (38, '-- execute the public procedure of the package
begin
    pkg_test.do;
end;
//

-- dbms_output doesn''t work, so we log into a table
-- (just like in real life) and select all records from it here
select *
from   log_table
//', '3c3c7a6bd5bd0d4007f2597361943d54', 1, '//', NULL);
INSERT INTO queries VALUES (39, '-- visit ForgeRock.com for details on the Open Identity Stack
-- sqlfiddle.com is built with OpenIDM

SELECT
  productName,
  description
FROM
  ForgeRock', '486c85215008690438a43ad3fab9b0f7', 1, ';', NULL);
INSERT INTO queries VALUES (40, '-- visit ForgeRock.com for details on the Open Identity Stack
-- sqlfiddle.com is built with OpenIDM

SELECT
  productName,
  description
FROM
  ForgeRock', '486c85215008690438a43ad3fab9b0f7', 1, ';', NULL);
INSERT INTO queries VALUES (42, 'SELECT
  jsonb_extract_path_text(data, ''b'') as b,
  jsonb_array_length(data->''c'') as numAnimals
FROM
  jsonData
WHERE
  jsonb_extract_path_text(data->''d'', ''x'') = ''true''
', '913643e9a39f17df60d6b1d94cabc3bc', 1, ';', NULL);
INSERT INTO queries VALUES (44, '-- visit ForgeRock.com for details on the Open Identity Stack
-- sqlfiddle.com is built with OpenIDM

SELECT
  productName,
  description
FROM
  ForgeRock', '486c85215008690438a43ad3fab9b0f7', 1, ';', NULL);
INSERT INTO queries VALUES (46, '-- visit ForgeRock.com for details on the Open Identity Stack
-- sqlfiddle.com is built with OpenIDM

SELECT
  productName,
  description
FROM
  ForgeRock', '486c85215008690438a43ad3fab9b0f7', 1, ';', NULL);


--
-- Name: schema_defs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('schema_defs_id_seq', 46, true);


--
-- PostgreSQL database dump complete
--
