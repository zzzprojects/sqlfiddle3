import javax.xml.validation.Schema

class QuerySet {
    private vertx
    private String sql
    private String statement_separator
    private String md5hash
    private Integer query_id
    private SchemaDef schemaDef

    QuerySet(vertx, content) {
        this.vertx = vertx
        this.schemaDef = new SchemaDef(this.vertx, content.db_type_id, content.schema_short_code)
        this.sql = content.sql
        this.statement_separator = content.statement_separator
        this.md5hash = RESTUtils.getMD5((String) statement_separator + sql)
    }

    def execute (fn) {
        this.schemaDef.getBasicDetails({
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
            [ this.schemaDef.getId(), this.md5hash ],
            { queryDetails ->
                if (this.schemaDef.getId() == null) {
                    fn([
                        "error": "Unable to find schema definition"
                    ])
                } else {
                    if (queryDetails == null) {
                        this.saveNewQuery({ query_id ->
                            this.query_id = query_id
                            this.getQueryResults(fn)
                        })
                    } else {
                        this.query_id = queryDetails.query_id
                        this.getQueryResults(fn)
                    }
                }
            }
            )
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
                        this.md5hash,
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
                                def query_id = DatabaseClient.queryResultAsBasicObj(it).result[0].query_id
                                connection.commit({
                                    connection.close()
                                    fn(query_id)
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
                            response.sets = results
                            hostConnection.close({
                                fn(response)
                            })
                        })
                    })
                },
                fn)
            } else {
                def host = new Host(this.schemaDef.getCurrentHostId())
                host.getUserHostConnection(this.vertx, this.schemaDef.getDatabaseName(), { hostConnection ->
                    this.executeSQLStatements(hostConnection, { results ->
                        response.sets = results
                        hostConnection.close({
                            fn(response)
                        })
                    })
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

            querySerially(hostConnection, queries, { resultSets ->
                hostConnection.rollback(fn(resultSets))
            })
        })
    }

    private static querySerially(connection, queries, fn) {
        def queryHandler
        def resultSets = []
        queryHandler = { queryQueue ->
            if (queryQueue.size() == 0) {
                fn(resultSets)
            } else {
                def query = queryQueue.get(0)
                queryQueue.remove(0)
                connection.query(query, { queryResult ->
                    resultSets.add(formatQueryResult(queryResult, query))
                    if (queryResult.succeeded()) {
                        queryHandler(queryQueue)
                    } else {
                        fn(resultSets)
                    }
                })
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
            set.ERRORMESSAGE = queryResult.cause().getMessage()
        }
        return set
    }

}
