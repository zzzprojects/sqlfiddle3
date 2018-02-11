#!/bin/bash

if [ "$MODE" = "DEVELOPMENT" ];
then
    cd /
    mv "$VERTICLE_HOME" "${VERTICLE_HOME}_static" && ln -s /tmp/target/docker/ $VERTICLE_HOME
    cd $VERTICLE_HOME
    # run grunt in the background to watch for changes to the source which come in via NFS
    (cd /tmp/target; grunt &)
fi

vertx run $VERTICLE_NAME -cp $VERTICLE_HOME/*
