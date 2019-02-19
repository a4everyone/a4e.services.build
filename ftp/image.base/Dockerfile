FROM alpine:3.6

RUN true \
    && apk add --no-cache openssh-sftp-server dropbear dropbear-convert rsync \
    && rm -rf /var/cache/apk/* \
    && mkdir /etc/dropbear \
    && touch /var/log/lastlog
