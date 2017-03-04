class QuerySet {
    private vertx
    private int db_type_id
    private String schema_short_code
    private String sql
    private String statement_separator
    private String md5hash
    private int query_id
    private int schema_def_id

    QuerySet(vertx, content) {
        this.vertx = vertx
        this.db_type_id = content.db_type_id
        this.schema_short_code = content.schema_short_code
        this.sql = content.sql
        this.statement_separator = content.statement_separator
        this.md5hash = RESTUtils.getMD5((String) statement_separator + sql)
    }

    def execute (fn) {
        // see if we can find existing data for this query
        DatabaseClient.singleRead(this.vertx, """
            SELECT
                d.simple_name,
                d.full_name,
                d.context,
                s.id as schema_def_id,
                q.id as query_id
            FROM
                db_types d
                    INNER JOIN schema_defs s ON
                        d.id = s.db_type_id AND
                        s.short_code = ?
                    LEFT OUTER JOIN queries q ON
                        s.id = q.schema_def_id AND
                        q.md5 = ?
            WHERE
                d.id = ?
            """,
                [ schema_short_code, md5hash, db_type_id ],
            { queryDetails ->
                if (queryDetails == null) {
                    fn([
                        "error": "Unable to find schema definition"
                    ])
                } else if (queryDetails.query_id == null) {
                    this.schema_def_id = queryDetails.schema_def_id
                    this.saveNewQuery({ query_id ->
                        this.query_id = query_id
                        this.getQueryResults(fn)
                    })
                } else {
                    this.query_id = queryDetails.query_id
                    this.schema_def_id = queryDetails.schema_def_id
                    this.getQueryResults(fn)
                }
            }
        )

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
                        this.schema_def_id,
                        this.schema_def_id
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
                                this.schema_def_id
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
        fn([ID: this.query_id, sets: []])
    }
}
