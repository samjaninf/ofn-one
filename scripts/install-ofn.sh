#!/bin/bash

set -ex

update-ca-certificates -f
#sed -i -e "s#.*tcp_nodelay on.*#        tcp_nodelay off;#" -e "s#.*\# gzip_vary on.*#        gzip_vary on;#" -e "s#.*\# gzip_proxied.*#        gzip_proxied any;#" -e "s#.*\# gzip_http_version.*#        gzip_http_version 1.1;#" -e "s#.*\# gzip_types text/plain text/css application/json application/javascriptt text/xml application/xml application/xml+rss text/javascript;.*#        gzip_types text/plain text/xml text/css text/comma-separated-values text/javascript application/x-javascript application/atom+xml;#" /etc/nginx/nginx.conf

