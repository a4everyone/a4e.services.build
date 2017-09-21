FROM docker:latest

ARG A4E_USER=a4e
ARG A4E_USER_HOME=/home/${A4E_USER}

ARG DOCKER_GROUP1
ARG DOCKER_GROUP2

COPY SERVER_JRE GLIBC_ALPINE GLIBC_ALPINE_BIN GLIBC_ALPINE_I18N /home/temp/ext/

RUN set -ex \
    && echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
    && apk upgrade --update \
    # shadow is for user management
    # libstdc++ is needed for GLIBC
    # gcc, python-dev, linux-headers, musl-dev, openssl-dev are needed for pyOpenSSL compilation
    # pyOpenSSL - ansible Vault prerequisite?
    # jmeshpath - needed to json_query filters
    && apk add --update gcc python-dev linux-headers musl-dev openssl-dev libstdc++ curl ca-certificates bash shadow nodejs git ansible py-pip openssh-client \
    && pip install --upgrade pip \
    && pip install ansible==2.4.0 \
#    && pip install git+git://github.com/ansible/ansible.git@devel \
    && pip install 'azure==2.0.0' pyOpenSSL packaging docker-py docker jmespath github3.py \
# The below pip packages should be automatically included dependencies to azure 2.0.0, but it seems they are not.
#
# on top of that, in /usr/lib/python2.7/site-packages/ansible/module_utils/azure_rm_common.py the api version for network_client (line 710) must be manually changed to '2015-06-15'
# https://github.com/ansible/ansible/issues/28916 described this problem, but hopefully bumping azure-mgmt-network version to 1.3.0 will solve it - needs testing
    && pip install azure-mgmt-containerservice azure-mgmt-network==1.3.0 \
# GLIBC (Prerequisite for Oracle Java)
    && for i in /home/temp/ext/GLIBC_ALPINE*; do cp $i ${i}.apk; done \
    && apk add --allow-untrusted /home/temp/ext/GLIBC_ALPINE.apk /home/temp/ext/GLIBC_ALPINE_BIN.apk /home/temp/ext/GLIBC_ALPINE_I18N.apk \
    && ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) \
    && echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib \
# JAVA
    && mkdir -p /opt \
    && tar -C /opt -xf /home/temp/ext/SERVER_JRE \
    && ln -s $(ls -d1 /opt/* | grep -E 'jdk[0-9]{1,2}.') ${JAVA_HOME} \
    && rm -rf /opt/jdk/*src.zip \
# DOCPAD
#    && npm install -g docpad@${VER_DOCPAD} \
# USER MGMT
    && groupadd -g 1001 ${A4E_USER} \
    && groupadd -o -g ${DOCKER_GROUP1} docker1 \
    && groupadd -o -g ${DOCKER_GROUP2} docker2 \
    && useradd ${A4E_USER} -g ${A4E_USER} -G ${DOCKER_GROUP1},${DOCKER_GROUP2} -s /bin/bash \
    && mkdir -p /home/${A4E_USER} \
    && chown -R ${A4E_USER}:${A4E_USER} ${A4E_USER_HOME} \
# CLEANUP
    && rm /etc/default/useradd \
    && rm -rf /home/temp \
    && apk del shadow glibc-i18n

USER ${A4E_USER}

ENTRYPOINT ["/bin/bash"]

ENV JAVA_HOME=/opt/jdk
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin
