FROM alpine:3.6

ARG A4E_USER=a4e
ARG A4E_USER_HOME=/home/${A4E_USER}

ENV A4E_USER_HOME=${A4E_USER_HOME}
ENV A4E_USER=${A4E_USER}

RUN true \
    && apk add --no-cache openssh-sftp-server dropbear dropbear-convert \
    && rm -rf /var/cache/apk/* \

    && mkdir /etc/dropbear \
    && touch /var/log/lastlog
