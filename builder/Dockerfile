FROM docker:latest

MAINTAINER A4E

ARG EXT_APP_PATH={{ common_paths.external_apps_rel }}

ARG JAVA_FILE_NAME={{ soft_versions.SERVER_JRE.FILE_NAMES[0] }}
ARG JAVA_VER_MINOR={{ soft_versions.SERVER_JRE.MINOR }}

ARG MAVEN_VER={{ soft_versions.MAVEN.VERSION }}
ARG MAVEN_FILE_NAME={{ soft_versions.MAVEN.FILE_NAMES[0] }}

ARG DOCPAD_VER={{ soft_versions.DOCPAD }}

COPY ${EXT_APP_PATH}/${JAVA_FILE_NAME} /tmp/java.tar.gz
COPY ${EXT_APP_PATH}/${MAVEN_FILE_NAME} /tmp/maven.tar.gz
COPY {% for app_file_name in soft_versions.GLIBC_ALPINE.FILE_NAMES %}{{ "${EXT_APP_PATH}/" + app_file_name + " " }}{% endfor %} /tmp/

ARG USER=a4everyone
ARG DOCKER_GROUP1={{ ansible_env.DOCKER_GROUP1 }}
ARG DOCKER_GROUP2={{ ansible_env.DOCKER_GROUP2 }}

ARG A4E_PROJ_ROOT=/a4e

RUN set -ex && \

    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk upgrade --update && \
    # shadow is for user management
    # libstdc++ is needed for GLIBC
    # gcc, python-dev, linux-headers, musl-dev, openssl-dev are needed for pyOpenSSL compilation
    # Why do we need pyOpenSSL, though?
    # jmeshpath - needed to json_query filters
    apk add --update gcc python-dev linux-headers musl-dev openssl-dev libstdc++ curl ca-certificates bash shadow nodejs git ansible py-pip openssh-client && \
    pip install --upgrade pip && \
    pip install git+git://github.com/ansible/ansible.git@devel && \
    pip install azure==2.0.0rc6 pyOpenSSL packaging docker-py docker jmespath && \

# GLIBC (Prerequisite for Oracle Java)
    apk add --allow-untrusted /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
# JAVA
    mkdir -p /opt && \
    tar -C /opt -xf /tmp/java.tar.gz && \
    ln -s $(ls -d1 /opt/* | grep -E "jdk.+${JAVA_VER_MINOR}.*") /opt/jdk && \
    rm -rf /opt/jdk/*src.zip && \
# MAVEN
    tar -C /opt -xf /tmp/maven.tar.gz && \
    ln -s /opt/apache-maven-${MAVEN_VER} /opt/maven && \
# DOCPAD
    npm install -g docpad@${DOCPAD_VER} && \
# USER MGMT
    groupadd -g 1001 ${USER} && \
    groupadd -o -g ${DOCKER_GROUP1} docker1 && \
    groupadd -o -g ${DOCKER_GROUP2} docker2 && \
    useradd ${USER} -g ${USER} -G ${DOCKER_GROUP1},${DOCKER_GROUP2} -s /bin/bash && \
    mkdir -p /home/${USER} && \
    chown -R ${USER}:${USER} /home/${USER} && \
    #echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
# CLEANUP
    rm /etc/default/useradd && \
    rm -rf /tmp/* && \
    apk del shadow glibc-i18n

USER ${USER}

ENTRYPOINT ["/bin/bash"]

ENV JAVA_HOME=/opt/jdk
ENV MAVEN_HOME=/opt/maven
ENV MAVEN_REPO=/home/${USER}/.m2/repository
ENV M2_REPO=/home/${USER}/.m2/repository
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin:${MAVEN_HOME}/bin
ENV A4E_PROJ_ROOT=${A4E_PROJ_ROOT}
