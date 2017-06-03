class Query {
    private vertx
    private String sql
    private String statement_separator
    private String md5
    private Integer query_id
    private SchemaDef schemaDef

    Query(vertx, content) {
        this.vertx = vertx
        this.schemaDef = new SchemaDef(this.vertx, content.db_type_id, content.schema_short_code)
        this.sql = content.sql
        this.statement_separator = content.statement_separator
        this.md5 = RESTUtils.getMD5((String) statement_separator + sql)
    }

    Query(vertx, db_type_id, short_code, query_id) {
        this.vertx = vertx
        this.schemaDef = new SchemaDef(this.vertx, db_type_id, short_code)
        this.query_id = query_id
    }

    def getBasicDetails (fn) {
        this.schemaDef.getBasicDetails({ schemaDetails ->
            if (!schemaDetails) {
                fn(null)
                return
            } else {
                DatabaseClient.singleRead(this.vertx, """
                SELECT
                    q.id,
                    q.sql,
                    q.statement_separator as query_statement_separator,
                    q.md5
                FROM
                    queries q
                WHERE
                    q.schema_def_id = ? AND
                    q.id = ?
                """,
                [ this.schemaDef.getId(), this.query_id ],
                { queryDetails ->
                    if (queryDetails == null) {
                        fn(null)
                        return
                    } else {
                        this.statement_separator = queryDetails.query_statement_separator
                        this.sql = queryDetails.sql
                        this.md5 = queryDetails.md5
                        fn(schemaDetails + queryDetails)
                    }
                })
            }
        })
    }

    def execute (fn) {
        this.schemaDef.getBasicDetails({
            if (this.schemaDef.getId() == null) {
                fn([
                    "error": "Unable to find schema definition"
                ])
            } else {
                // see if we can find existing data for this query
                DatabaseClient.singleRead(this.vertx, """
                SELECT
                    q.id as query_id
                FROM
                    queries q
                WHERE
                    q.schema_def_id = ? AND
                    q.md5 = ?
                """,
                [ this.schemaDef.getId(), this.md5 ],
                { queryDetails ->
                    if (queryDetails == null) {
                        this.saveNewQuery({
                            this.getQueryResults(fn)
                        })
                    } else {
                        this.query_id = queryDetails.query_id
                        this.getQueryResults(fn)
                    }
                })
            }
        })
    }

    private saveNewQuery(fn) {
        DatabaseClient.getConnection(this.vertx, { connection ->
            connection.setAutoCommit(false, {
                connection.updateWithParams("""
                    INSERT INTO
                        queries
                    (
                        id,
                        md5,
                        sql,
                        statement_separator,
                        schema_def_id
                    )
                    SELECT
                        count(*) + 1, ?, ?, ?, ?
                    FROM
                        queries
                    WHERE
                        schema_def_id = ?
                    """,
                    [
                        this.md5,
                        this.sql,
                        this.statement_separator,
                        this.schemaDef.getId(),
                        this.schemaDef.getId()
                    ],
                    {
                        connection.queryWithParams("""
                            SELECT
                                max(id) as query_id
                            FROM
                                queries
                            WHERE
                                schema_def_id = ?
                            """,
                            [
                                this.schemaDef.getId()
                            ],
                            {
                                this.query_id = DatabaseClient.queryResultAsBasicObj(it).result[0].query_id
                                connection.commit({
                                    connection.close(fn)
                                })
                            }
                        )
                    }
                )
            })
        })
    }

    private getQueryResults(fn) {
        def response = [ID: this.query_id, sets: []]

        if (this.schemaDef.getContext() == "host") {
            if (this.schemaDef.getCurrentHostId() == null) {
                schemaDef.buildRunningDatabase({ host, hostConnection ->
                    schemaDef.updateCurrentHost(host.host_id, {
                        this.executeSQLStatements(hostConnection, { results ->
                            response.sets = results ?: []
                            hostConnection.close({
                                fn(response)
                            })
                        })
                    })
                },
                {
                    fn([
                        "error": it
                    ])
                })
            } else {
                def host = new Host(this.schemaDef.getCurrentHostId())
                host.getUserHostConnection(this.vertx, this.schemaDef.getDatabaseName(), { hostConnection ->
                    this.executeSQLStatements(hostConnection, { results ->
                        response.sets = results ?: []
                        hostConnection.close({
                            fn(response)
                        })
                    })
                }, {
                    fn([
                        "error": it
                    ])
                })
            }
        } else {
            // non-host context
            fn(response)
        }
    }

    private executeSQLStatements(hostConnection, fn) {
        hostConnection.setAutoCommit(false, {
            def queries = DatabaseClient.parseStatementGroups(this.sql,
                this.statement_separator,
                this.schemaDef.getBatchSeparator())
            def hasExecutionPlan = this.schemaDef.getExecutionPlanPrefix().size() > 0 || this.schemaDef.getExecutionPlanSuffix().size() > 0

            querySerially(hostConnection, queries, hasExecutionPlan, { resultSets ->
                hostConnection.rollback(fn(resultSets))
            })
        })
    }

    private querySerially(connection, queries, includeExecutionPlan, fn) {
        def queryHandler
        def resultSets = []
        queryHandler = { queryQueue ->
            if (queryQueue.size() == 0) {
                fn(resultSets)
            } else {
                def query = queryQueue.get(0)
                queryQueue.remove(0)

                if (includeExecutionPlan) {
                    def executionPlan = null
                    def finalExecutionPlanResults = [processed : null, raw : null]

                    // execution plan able to be computed, therefore get it before we run the main query
                    def executionPlanSQL = this.schemaDef.getExecutionPlanPrefix() + query + this.schemaDef.getExecutionPlanSuffix()
                    executionPlanSQL = executionPlanSQL.replaceAll("#schema_short_code#", this.schemaDef.getShortCode())
                    executionPlanSQL = executionPlanSQL.replaceAll("#query_id#", this.query_id.toString())
                    def executionPlanStatements = DatabaseClient.parseStatementGroups(executionPlanSQL, ";", this.schemaDef.getBatchSeparator())

                    // call this same function but with "false" for "includeExecutionPlan"
                    querySerially(connection, executionPlanStatements, false, { executionPlanResultSets ->
                        executionPlan = executionPlanResultSets[executionPlanResultSets.size()-1] // the last record is the one we want here
                        if (executionPlan.SUCCEEDED && executionPlan.RESULTS.COLUMNS.size() > 0) {
                            finalExecutionPlanResults.processed = executionPlan.RESULTS
                            finalExecutionPlanResults.raw = executionPlan.RESULTS

                            /*
                                TODO: restore this xslt logic from sqlfiddle2

                                if (db_type.execution_plan_xslt?.size() &&
                                    executionPlan.RESULTS.COLUMNS?.size() == 1 &&
                                    executionPlan.RESULTS.DATA?.size() == 1) {
                                    try {
                                        def factory = TransformerFactory.newInstance()
                                        def transformer = factory.newTransformer(new StreamSource(new StringReader(db_type.execution_plan_xslt)))
                                        def outputStream = new ByteArrayOutputStream()
                                        transformer.transform(new StreamSource(new StringReader(executionPlanResults.raw.DATA[0][0])), new StreamResult(outputStream))

                                        executionPlanResults.processed.DATA[0][0] = new String(outputStream.toByteArray(), Charset.defaultCharset())
                                    } catch (e) {
                                        // unable to parse the execution plan results
                                    }
                                }
                         */

                        }

                        long startTime = (new Date()).toTimestamp().getTime()
                        connection.query(query, { queryResult ->
                            def set = formatQueryResult(queryResult, query)
                            set.EXECUTIONTIME = ((new Date()).toTimestamp().getTime() - startTime)
                            set.EXECUTIONPLANRAW = finalExecutionPlanResults.raw
                            set.EXECUTIONPLAN = finalExecutionPlanResults.processed

                            resultSets.add(set)
                            if (set.SUCCEEDED) {
                                queryHandler(queryQueue)
                            } else {
                                fn(resultSets)
                            }
                        })
                    })
                } else {

                    // TODO: refactor so share with above logic
                    long startTime = (new Date()).toTimestamp().getTime()
                    connection.query(query, { queryResult ->
                        def set = formatQueryResult(queryResult, query)
                        set.EXECUTIONTIME = ((new Date()).toTimestamp().getTime() - startTime)
                        resultSets.add(set)
                        if (set.SUCCEEDED) {
                            queryHandler(queryQueue)
                        } else {
                            fn(resultSets)
                        }
                    })
                }

            }
        }
        queryHandler(queries)
    }

    private static formatQueryResult(queryResult, query) {
        def set = [RESULTS: [ COLUMNS: [], DATA: [] ], SUCCEEDED:queryResult.succeeded(), STATEMENT: query]

        if (set.SUCCEEDED) {
            set.RESULTS.COLUMNS = queryResult.result().columnNames
            set.RESULTS.DATA = queryResult.result().results
        } else {
            def errorMessage = queryResult.cause().getMessage()
            if ((errorMessage =~ /ResultSet is from UPDATE\. No Data\./).find() || // MySQL when using SELECT ... INTO @var
                (errorMessage =~ /No results were returned by the query/).find() || // PostgreSQL
                (errorMessage =~ /The executeQuery method must return a result set\./).find() || // SQL Server
                (errorMessage =~ /Cannot perform fetch on a PLSQL statement/).find() || // Oracle
                (errorMessage =~ /ORA-01002: fetch out of sequence/).find() || // Also Oracle
                (errorMessage =~ /ORA-00900: invalid SQL statement/).find() // Oracle again :(
                ) {
                set.SUCCEEDED = true
            } else if ((errorMessage =~ /current transaction is aborted, commands ignored until end of transaction block$/).find()) {
                //throw new PostgreSQLException(statement)
                set.ERRORMESSAGE = errorMessage
            } else if ((errorMessage =~ /insert or update on table "deferred_.*" violates foreign key constraint "deferred_.*_ref"/).find()) {
                set.ERRORMESSAGE = "Explicit commits are not allowed within the query panel."
            } else if ((errorMessage =~ /Cannot execute statement in a READ ONLY transaction./).find() ||
                    (errorMessage =~ /Can not issue data manipulation statements with executeQuery/).find()) {
                set.ERRORMESSAGE = "DDL and DML statements are not allowed in the query panel for MySQL; only SELECT statements are allowed. Put DDL and DML in the schema panel."
            } else {
                set.ERRORMESSAGE = errorMessage
            }
        }
        return set
    }

}
