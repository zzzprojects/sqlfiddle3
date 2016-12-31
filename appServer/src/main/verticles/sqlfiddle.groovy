import io.vertx.groovy.core.Vertx
import io.vertx.groovy.ext.web.handler.StaticHandler
import io.vertx.groovy.ext.web.Router
import io.vertx.core.json.JsonObject

import io.vertx.groovy.ext.jdbc.JDBCClient

def server = vertx.createHttpServer()
def router = Router.router(vertx)
def jdbcConfig = [
    url: "jdbc:postgresql://appDatabase:5432/sqlfiddle",
    driver_class: "org.postgresql.Driver",
    user: "postgres",
    password: "password"
]
def client = JDBCClient.createShared(vertx, jdbcConfig, "SQLFiddle")

router.route("/sqlfiddle/*").handler(StaticHandler.create())

router.route("/dbTypes").handler({ routingContext ->
    def response = routingContext.response()
    response.putHeader("content-type", "application/json")

    client.getConnection({ res ->
        if (res.succeeded()) {
            def connection = res.result()
            connection.query("""
        SELECT
            d.id,
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
    """, { dbTypes ->
                if (dbTypes.succeeded()) {
                    def columnNames = dbTypes.result().columnNames
                    response.end(
                        new JsonObject([
                            result: dbTypes.result().results.collect { row ->
                                def valueMap = [:]
                                columnNames.eachWithIndex { col, pos ->
                                    valueMap[col] = row[pos]
                                }
                                return valueMap
                            }
                        ]).encodePrettily()
                    )
                } else {
                    response.end([
                        message: dbTypes.cause().getMessage()
                    ].encodePrettily())
                }
            })
        }
    })
})

server.requestHandler(router.&accept).listen(8080)
