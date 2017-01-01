import io.vertx.groovy.core.Vertx
import io.vertx.groovy.ext.web.handler.StaticHandler
import io.vertx.groovy.ext.web.Router


def server = vertx.createHttpServer()
def router = Router.router(vertx)

router.route().pathRegex("^(?!/backend)/.*").handler(StaticHandler.create())

router.route("/backend/dbTypes").handler({ routingContext ->
    DBTypes.getAllTypes(vertx, { dbTypes ->
        RESTUtils.writeJSONResponse(
            routingContext,
            RESTUtils.queryResultAsBasicObj(dbTypes)
        )
    })
})

server.requestHandler(router.&accept).listen(8080)
