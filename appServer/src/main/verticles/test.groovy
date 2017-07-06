import io.vertx.ext.jdbc.JDBCClient
import io.vertx.core.Vertx
import io.vertx.core.json.JsonObject
import java.sql.Connection
import java.sql.SQLException

def vertx = Vertx.vertx()

JDBCClient.createShared(vertx, new JsonObject([
    url: "jdbc:jtds:sqlserver://sqlserver2014Host:1433/master",
    driver_class: "net.sourceforge.jtds.jdbc.Driver",
    user: "sa",
    password: "SQLServerPassword",
    initial_pool_size: 2,
    min_pool_size: 2,
    max_pool_size: 4,
    max_idle_time: 10
]), "test").getConnection({ connHandler ->
    if (connHandler.succeeded()) {
        def conn = connHandler.result()
        def result

        Connection nativeConn = (Connection) conn.unwrap()

        try {
            nativeConn.createStatement().executeQuery("SET SHOWPLAN_XML ON")
        } catch (SQLException se) { }

        try {
            result = nativeConn.createStatement().executeQuery("SELECT 1 as foo")
        } catch (SQLException se) { }

        try {
            nativeConn.createStatement().executeQuery("SET SHOWPLAN_XML OFF")
        } catch (SQLException se) { }

        println result.getMetaData().getColumnName(1)


        conn.execute("SET SHOWPLAN_XML ON", {
            conn.query("SELECT 1 as foo", { query2 ->
                println query2.result().columnNames
                conn.execute("SET SHOWPLAN_XML OFF", {
                    conn.query("SELECT 1 as foo", { query4 ->
                        println query4.result().columnNames
                        conn.close()
                    })
                })
            })
        })

    }
})
