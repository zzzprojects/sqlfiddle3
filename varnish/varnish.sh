#!/bin/sh

sed -i s/\${VARNISH_BACKEND_HOST}/${VARNISH_BACKEND_HOST}/ /etc/varnish/default.vcl
sed -i s/\${VARNISH_BACKEND_PORT}/${VARNISH_BACKEND_PORT}/ /etc/varnish/default.vcl

mkdir -p /var/lib/varnish/`hostname` && chown nobody /var/lib/varnish/`hostname`
varnishd -s malloc,256m -a :8080 -f /etc/varnish/default.vcl

sleep 1

varnishlog
