class DBTypes {
    static def getAllTypes(vertx, fn) {
        DatabaseClient.getConnection(vertx, {connection ->
            connection.query("""
            SELECT
                d.id as db_type_id,
                d.context,
                d.full_name,
                d.simple_name,
                d.jdbc_class_name,
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
        """, fn)
        })
    }
}
