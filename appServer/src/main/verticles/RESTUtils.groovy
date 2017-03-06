import io.vertx.core.json.JsonObject
import java.security.MessageDigest

class RESTUtils {
    static writeJSONResponse(routingContext, responseObj) {
        def response = routingContext.response()
        response.putHeader("content-type", "application/json")
        response.end((new JsonObject(responseObj)).encodePrettily())
    }

    static write404Response(routingContext) {
        def response = routingContext.response()
        response.putHeader("content-type", "application/json")
        response.setStatusCode(404)
        response.end((new JsonObject(["error":"Not found"])).encodePrettily())
    }

    static String getMD5(String content) {
        def digest = MessageDigest.getInstance("MD5")
        return new BigInteger(
                1, digest.digest((content).getBytes())
        ).toString(16).padLeft(32,"0")
    }
}
