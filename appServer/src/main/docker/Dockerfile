FROM vertx/vertx3:3.4.2

ENV VERTICLE_NAME sqlfiddle.groovy
ENV VERTICLE_HOME /usr/verticles
ENV VERTX_HOME /usr/local/vertx

EXPOSE 8080
EXPOSE 5005

COPY webroot $VERTICLE_HOME/webroot
COPY lib $VERTX_HOME/lib
COPY *.groovy $VERTICLE_HOME/


WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["vertx run $VERTICLE_NAME -cp $VERTICLE_HOME/*"]
