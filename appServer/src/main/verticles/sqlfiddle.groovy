import io.vertx.groovy.core.Vertx
import io.vertx.groovy.ext.web.handler.StaticHandler
import io.vertx.groovy.ext.web.Router

import io.vertx.groovy.ext.jdbc.JDBCClient

def server = vertx.createHttpServer()
def router = Router.router(vertx)
def jdbcConfig = [
    url: "jdbc:postgresql://appdb:5432/sqlfiddle",
    driver_class: "org.postgresql.Driver",
    user: "postgres"
]
def client = JDBCClient.createShared(vertx, jdbcConfig, "SQLFiddle")

router.route("/sqlfiddle/*").handler(StaticHandler.create())

router.route("/dbTypes").handler({
    client.getConnection({ res ->

    })
})

server.requestHandler(router.&accept).listen(8080)
