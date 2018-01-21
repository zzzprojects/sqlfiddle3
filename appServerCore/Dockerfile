FROM vertx/vertx3:3.4.2

ENV VERTICLE_NAME sqlfiddle.groovy
ENV VERTICLE_HOME /usr/verticles
ENV VERTX_HOME /usr/local/vertx

EXPOSE 8080
EXPOSE 5005

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" | tee -a /etc/apt/sources.list
RUN apt-get update && apt-get -t jessie-backports install --yes maven

COPY src /tmp/src
COPY pom.xml /tmp

RUN (cd /tmp; mvn package)
RUN cp -R /tmp/target/docker $VERTICLE_HOME

RUN cp -R $VERTICLE_HOME/lib/* $VERTX_HOME/lib

WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["vertx run $VERTICLE_NAME -cp $VERTICLE_HOME/*"]
