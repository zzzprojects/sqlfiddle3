import io.vertx.groovy.ext.web.handler.BodyHandler
import io.vertx.groovy.ext.web.handler.StaticHandler
import io.vertx.groovy.ext.web.Router

def router = Router.router(vertx)
router.route().handler(BodyHandler.create().setBodyLimit(8000))

router.route().pathRegex("^(?!/backend)/.*").handler(StaticHandler.create())

router.route("/backend/dbTypes").handler({ routingContext ->
    DBTypes.getAllTypes(vertx, { dbTypes ->
        RESTUtils.writeJSONResponse(routingContext, dbTypes)
    })
})

router.post("/backend/createSchema").handler({ routingContext ->
    (new SchemaDef(vertx)).processCreateRequest(routingContext.getBodyAsJson(), { response ->
        RESTUtils.writeJSONResponse(routingContext, response)
    })
})

router.post("/backend/executeQuery").handler({ routingContext ->
    (new QuerySet(vertx, routingContext.getBodyAsJson())).execute({ response ->
        RESTUtils.writeJSONResponse(routingContext, response)
    })
})

def server = vertx.createHttpServer()
server.requestHandler(router.&accept).listen(8080)
