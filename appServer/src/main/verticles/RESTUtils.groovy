import io.vertx.core.json.JsonObject

class RESTUtils {
    static def writeJSONResponse(routingContext, responseObj) {
        def response = routingContext.response()
        response.putHeader("content-type", "application/json")
        response.end((new JsonObject(responseObj)).encodePrettily())
    }
}
