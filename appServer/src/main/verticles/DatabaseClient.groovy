import io.vertx.groovy.ext.jdbc.JDBCClient

class DatabaseClient {
    static private def jdbcConfig = [
        url: "jdbc:postgresql://appDatabase:5432/sqlfiddle",
        driver_class: "org.postgresql.Driver",
        user: "postgres",
        password: "password"
    ]
    static def getConnection(vertx, fn) {
        JDBCClient
            .createShared(vertx, jdbcConfig, "SQLFiddle")
            .getConnection({ dbConnectionHandler ->
                if (dbConnectionHandler.succeeded()) {
                    fn(dbConnectionHandler.result())
                } else {
                    throw "Unable to get connection: " +
                        dbConnectionHandler.cause().getMessage()
                }
            })
    }
}
