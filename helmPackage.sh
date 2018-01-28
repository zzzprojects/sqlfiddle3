#!/bin/bash

ARG=$1

function makePackage {

    PACKAGE_NAME="$1";

    helm package $PACKAGE_NAME;

    PACKAGE_VERSION=`ls | grep tgz`;

    if [ -e "charts/${PACKAGE_VERSION}" ];
    then
        NEW_MD5=`md5sum ${PACKAGE_VERSION}  | cut -f1 -d' '`;
        EXISTING_MD5=`md5sum charts/${PACKAGE_VERSION}  | cut -f1 -d' '`;
        if [ "$NEW_MD5" != "$EXISTING_MD5" ];
        then
            if [ "$ARG" = "-f" ];
            then
                echo "Warning: replacing existing charts/$PACKAGE_VERSION";
                mv $PACKAGE_VERSION charts;
            else
                echo "Chart $PACKAGE_VERSION already exists; update chart version and re-run or use -f to force";
                rm $PACKAGE_VERSION;
                exit 1;
            fi
        fi
    else
        mv $PACKAGE_VERSION charts;
    fi
}

makePackage sqlfiddleOpenCore;
rm -rf sqlfiddleCommercialExtension/charts/*.tgz;
cp charts/$PACKAGE_VERSION sqlfiddleCommercialExtension/charts;
makePackage sqlfiddleCommercialExtension;

helm repo index charts;
