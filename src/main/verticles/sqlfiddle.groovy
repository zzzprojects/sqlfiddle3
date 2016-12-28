import io.vertx.groovy.core.Vertx
import io.vertx.groovy.ext.web.handler.StaticHandler
import io.vertx.groovy.ext.web.Router

def server = vertx.createHttpServer()
def router = Router.router(vertx)

router.route("/sqlfiddle/*").handler(StaticHandler.create())

server.requestHandler(router.&accept).listen(8080)
