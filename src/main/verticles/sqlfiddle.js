var Router = require("vertx-web-js/router");
var StaticHandler = require("vertx-web-js/static_handler");
var router = Router.router(vertx);

// UI files
router.route("/sqlfiddle/*").handler(StaticHandler.create().handle);



vertx.createHttpServer().requestHandler(router.accept).listen(8080);
