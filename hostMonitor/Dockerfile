FROM debian:9.3

RUN apt-get update && apt-get --yes install curl software-properties-common gnupg
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -
RUN apt-get --yes install nodejs

COPY monitorApp /monitorApp

RUN (cd /monitorApp; npm install)

CMD (cd /monitorApp; node hostMonitor.js)
