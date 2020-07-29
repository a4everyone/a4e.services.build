#! /bin/bash

cat /home/nginx.conf.tmpl | envsubst \'$(env | grep ^NG_ | awk 'BEGIN{FS="=";ORS="";}{print "$"$1}')\' > /etc/nginx/conf.d/nginxa4e.conf

exec nginx -g "daemon off;"
