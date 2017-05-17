#!/bin/bash
if [ "$LAMBDA_NOTIFICATION_URL" != "" ]; then
    curl -v "$LAMBDA_NOTIFICATION_URL?containerType=mysql56&ipAddress=`hostname -i`";
fi
