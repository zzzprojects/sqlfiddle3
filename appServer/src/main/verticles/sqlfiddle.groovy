import io.vertx.core.http.HttpMethod
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

router.route(HttpMethod.GET, "/backend/loadContent/:dbtypeid/:shortcode").handler({ routingContext ->
    Integer db_type_id
    String short_code

    try {
        db_type_id = Integer.parseInt(routingContext.request().getParam("dbtypeid"))
        short_code = routingContext.request().getParam("shortcode")
    } catch (NumberFormatException e) {
        RESTUtils.write404Response(routingContext)
        return
    }
    (new SchemaDef(vertx, db_type_id, short_code)).getBasicDetails({ response ->
        if (!response) {
            RESTUtils.write404Response(routingContext)
        } else {
            RESTUtils.writeJSONResponse(routingContext, response)
        }
    })
})

router.route(HttpMethod.GET, "/backend/loadContent/:dbtypeid/:shortcode/:queryid").handler({ routingContext ->
    Integer db_type_id
    String short_code
    Integer query_id

    try {
        db_type_id = Integer.parseInt(routingContext.request().getParam("dbtypeid"))
        short_code = routingContext.request().getParam("shortcode")
        query_id = Integer.parseInt(routingContext.request().getParam("queryid"))
    } catch (NumberFormatException e) {
        RESTUtils.write404Response(routingContext)
        return
    }

    def querySet = new QuerySet(vertx, db_type_id, short_code, query_id)

    querySet.getBasicDetails({ response ->
        if (!response) {
            RESTUtils.write404Response(routingContext)
        } else {
            querySet.execute({ resultSets ->
                response.sets = resultSets.sets
                RESTUtils.writeJSONResponse(routingContext, response)
            })
        }
    })

})



def server = vertx.createHttpServer()
server.requestHandler(router.&accept).listen(8080)
