FROM vertx/vertx3:latest

ENV VERTICLE_NAME sqlfiddle.groovy

ENV VERTICLE_HOME /usr/verticles
ENV VERTX_HOME /usr/local/vertx
ENV VERTX_OPTS '-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005'

EXPOSE 8080
EXPOSE 5005

COPY webroot $VERTICLE_HOME/webroot
COPY lib $VERTX_HOME/lib
COPY *.groovy $VERTICLE_HOME/

WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["vertx run $VERTICLE_NAME -cp $VERTICLE_HOME/*"]
