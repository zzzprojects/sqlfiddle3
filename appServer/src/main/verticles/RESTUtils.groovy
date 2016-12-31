import io.vertx.core.json.JsonObject
import io.vertx.core.impl.FutureImpl


class RESTUtils {

    static def queryResultAsBasicObj(FutureImpl queryResult) {
        if (queryResult.succeeded()) {
            def columnNames = queryResult.result().columnNames
            return [
                    result: queryResult.result().results.collect { row ->
                        def valueMap = [:]
                        columnNames.eachWithIndex { col, pos ->
                            valueMap[col] = row[pos]
                        }
                        return valueMap
                    }
                ]
        } else {
            return [
                message: queryResult.cause().getMessage()
            ]
        }
    }

    static def writeJSONResponse(routingContext, responseObj) {
        def response = routingContext.response()
        response.putHeader("content-type", "application/json")
        response.end((new JsonObject(responseObj)).encodePrettily())
    }
}
