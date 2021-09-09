FROM debian:buster-slim

RUN true \
    && apt-get update \
    && apt-get install -y openssh-server acl iptables gosu \
    && rm -rf /var/cache/apt/* \
# rsync will be used on the sidecar container for backups