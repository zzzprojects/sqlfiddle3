FROM vertx/vertx3:3.9.0

ENV VERTICLE_NAME sqlfiddle.groovy
ENV VERTICLE_HOME /usr/verticles
ENV VERTX_HOME /usr/local/vertx

EXPOSE 8080
EXPOSE 5005

RUN apt-get update && apt-get install --yes maven

COPY src /tmp/src
COPY pom.xml /tmp

RUN (cd /tmp; mvn package)
RUN cp -R /tmp/target/docker $VERTICLE_HOME

RUN cp -R $VERTICLE_HOME/lib/* $VERTX_HOME/lib

ENV PATH /tmp/target/node_modules/grunt-cli/bin:/tmp/target/node:/usr/local/vertx/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY run.sh $VERTICLE_HOME

WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["$VERTICLE_HOME/run.sh"]
