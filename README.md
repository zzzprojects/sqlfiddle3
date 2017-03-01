# SQL Fiddle, take 3 (or so?)

This version of the system is intended to make use of Docker for the different systems (app server, app database, fiddle databases, etc...)

It is also implemented with Vert.x in the application tier.

To get running:

    cd appServer/ && mvn clean package && cd .. && docker-compose up -d

If building on a Mac, be sure to prep docker first:

    docker-machine start
    eval $(docker-machine env)


To do development in a local environment (requires local install of PostgreSQL and Vert.x):

    cd appServer/
    mvn clean package
    grunt &
    cd target/docker
    # next line is for connecting with a remote debugger such as IntelliJ
    export VERTX_OPTS='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005'
    CLASSPATH=".:lib/*" vertx run sqlfiddle.groovy
