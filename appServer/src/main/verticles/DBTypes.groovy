class DBTypes {
    static private String getSQL(where) {
        return """
        SELECT
            d.id as db_type_id,
            d.context,
            d.full_name,
            d.simple_name,
            d.jdbc_class_name as "className",
            d.sample_fragment,
            d.batch_separator,
            d.execution_plan_prefix,
            d.execution_plan_suffix,
            d.execution_plan_xslt,
            count(h.id) as num_hosts
        FROM
            db_types d
                LEFT OUTER JOIN hosts h ON
                    d.id = h.db_type_id
        ${where}
        GROUP BY
            d.id,
            d.context,
            d.full_name,
            d.simple_name,
            d.jdbc_class_name,
            d.sample_fragment,
            d.batch_separator,
            d.execution_plan_prefix,
            d.execution_plan_suffix,
            d.execution_plan_xslt
        ORDER BY
            d.simple_name,
            d.is_latest_stable desc,
            d.full_name desc
    """
    }

    static getAllTypes(vertx, fn) {
        DatabaseClient.getConnection(vertx, {connection ->
            connection.query(getSQL(""), {
                connection.close()
                fn(DatabaseClient.queryResultAsBasicObj(it))
            })
        })
    }

    static findAvailableHost(vertx, db_type_id, successHandler, failureHandler) {
        DatabaseClient.singleRead(vertx, """
            SELECT
                h.id as host_id,
                h.db_type_id,
                h.jdbc_url_template,
                h.default_database,
                h.admin_username,
                h.admin_password,
                d.setup_script_template,
                d.drop_script_template,
                d.batch_separator,
                d.jdbc_class_name
            FROM
                Hosts h
                    INNER JOIN db_types d ON
                        h.db_type_id = d.id
            WHERE
                h.db_type_id = ? AND
                not exists (
                    SELECT
                        1
                    FROM
                        Hosts h2
                    WHERE
                        h2.id != h.id AND
                        h2.db_type_id = h.db_type_id AND
                        coalesce((SELECT count(s.id) FROM schema_defs s WHERE s.current_host_id = h2.id), 0) <
                        coalesce((SELECT count(s.id) FROM schema_defs s WHERE s.current_host_id = h.id), 0)
                )
        """, [db_type_id], { result ->
            if (result != null) {
                successHandler(new Host((Map) result))
            } else {
                failureHandler()
            }
        })
    }

}
