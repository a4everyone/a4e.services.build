FROM ubuntu:focal

ARG A4E_USER=a4e
ARG A4E_USER_HOME=/home/${A4E_USER}

ARG DOCKER_GROUP1
ARG DOCKER_GROUP2

RUN addgroup --gid=1000 ${A4E_USER} \
    && adduser --uid=1000 --gid=1000 --disabled-password --gecos "" a4e \
    && addgroup --gid ${DOCKER_GROUP1} docker1 \
    && addgroup --gid ${DOCKER_GROUP2} docker2 \
    && adduser ${A4E_USER} docker1 \
    && adduser ${A4E_USER} docker2
RUN apt-get update \
    && apt-get install -y curl software-properties-common python3-distutils bash-completion openssh-client xclip jq

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/a4e/.local/bin

# Ansible 2.10 is only compatible with azure-cli 2.16, be careful when you move versions because there was some guesswork here to achieve compliance
# Also using azure-storage, which is an obsolete library, was necessary because otherwise Ansible would prodice errors.
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && python3 -m pip install twine ansible==2.10 azure-cli==2.16 azure-storage==0.36 azure-mgmt-automation==0.1.1 \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.20.1/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl
# azure-cli 2.16 requires this version.py, but otherwise works with azure-storage 0.36
RUN cp /usr/local/lib/python3.8/dist-packages/azure/mgmt/storage/_version.py /usr/local/lib/python3.8/dist-packages/azure/mgmt/storage/version.py

RUN ansible-galaxy collection install azure.azcollection:==1.3.1 \
    && echo 'source /usr/share/bash-completion/bash_completion' >> ${A4E_USER_HOME}/.bashrc \
    && echo 'source <(kubectl completion bash)' >> ${A4E_USER_HOME}/.bashrc \
    && echo 'alias k=kubectl' >> ${A4E_USER_HOME}/.bashrc \
    && echo 'alias fromclip="xclip -selection clipboard -o"' >> ${A4E_USER_HOME}/.bashrc \
    && echo 'alias toclip="xclip -selection c"' >> ${A4E_USER_HOME}/.bashrc \
    && echo 'complete -F __start_kubectl k' >> ${A4E_USER_HOME}/.bashrc

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
    && echo 'source <(helm completion bash)' >> ${A4E_USER_HOME}/.bashrc

RUN cd /usr/bin && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

USER ${A4E_USER}

ENTRYPOINT ["/bin/bash"]
