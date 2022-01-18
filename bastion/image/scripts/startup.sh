#! /bin/bash

set -e

source /scripts/bootstrap.sh

cp -fpP $USER_META_PATH/passwd $USER_META_PATH/shadow $USER_META_PATH/group /etc/

chown ${A4E_USER}:${A4E_INTERNAL_GROUP} /home/ftp_users
# Originally it was 751, but since this is a mounted disk, kubernetes automatically gives it 771 when mounted with the "fsGroup" setting.
# As a workaround we could put the ftp_users folder one level deeper, but I think we can just live with ftp_users having 771 permissions for now
chmod 771 /home/ftp_users

# Make sure the authorized keys for a4e exist
# This is happening in a directory which is not a volume, so the init container can't do it for us
mkdir -p -m 750 ${A4E_USER_HOME}/.ssh/
cp ${AUTHORIZED_SECRETS_PATH}/a4e ${A4E_USER_HOME}/.ssh/authorized_keys
chown -R ${A4E_USER}:${A4E_USER} ${A4E_USER_HOME}/.ssh

umask 007
exec /usr/sbin/sshd -D -h ${PRIVATE_SECRETS_PATH}/host_key_rsa -h ${PRIVATE_SECRETS_PATH}/host_key_ecdsa -p ${SFTP_PORT}
