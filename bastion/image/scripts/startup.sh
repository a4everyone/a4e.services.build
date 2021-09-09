#! /bin/bash
# Making sure the local volume has prоper privileges at runtime.
chmod o-r /

set -e

export PRIVATE_SECRETS_PATH=${PRIVATE_SECRETS_PATH:-"/secrets/private"}
export AUTHORIZED_SECRETS_PATH=${AUTHORIZED_SECRETS_PATH:-"/secrets/authorized"}

export A4E_INTERNAL_GUID=1002
export A4E_INTERNAL_GROUP=a4e_internal
a4e_internal_curr_guid=$(getent group ${A4E_INTERNAL_GROUP} | cut -d: -f3)
# Check for a4e_internal group
if [ -n "$a4e_internal_curr_guid" ] && [ "$a4e_internal_curr_guid" -ne "$A4E_INTERNAL_GUID" ]; then
    echo "CRITICAL: The current GUID for group ${A4E_INTERNAL_GROUP} is ${a4e_internal_curr_guid}, but the configuration says it should be ${A4E_INTERNAL_GUID}."
    echo "The system will not start due to the above critical error"
    false
fi
# Create the A4E_INTERNAL_GUID group if it doesn't exist
if [ -z "$a4e_internal_curr_guid" ]; then
    addgroup --gid ${A4E_INTERNAL_GUID} ${A4E_INTERNAL_GROUP}
fi

chown ${A4E_USER}:${A4E_INTERNAL_GROUP} /home/ftp_users
chmod 751 /home/ftp_users

# Convert input config variables as convenient associative arrays
declare -A CNF_INT_SERVICE_GROUPS_ARR
for f in $CNF_INT_SERVICE_GROUPS; do CNF_INT_SERVICE_GROUPS_ARR[${f%%=*}]=${f#*=}; done
echo ${CNF_INT_SERVICE_GROUPS_ARR[@]}
declare -A CNF_INT_SERVICE_ACCESS_ARR
for f in $CNF_INT_SERVICE_ACCESS; do CNF_INT_SERVICE_ACCESS_ARR[${f%%=*}]=${f#*=}; done
echo ${CNF_INT_SERVICE_ACCESS_ARR[@]}
declare -A CNF_FTP_CLI_ACCESS_ARR
for f in $CNF_FTP_CLI_ACCESS; do CNF_FTP_CLI_ACCESS_ARR[${f%%=*}]=${f#*=}; done
echo ${CNF_FTP_CLI_ACCESS_ARR[@]}
declare -A CNF_INT_SERVICE_PORTS_ARR
for f in $CNF_INT_SERVICE_PORTS; do CNF_INT_SERVICE_PORTS_ARR[${f%%=*}]=${f#*=}; done
echo ${CNF_INT_SERVICE_PORTS_ARR[@]}

declare -A FTP_USER_TYPES_ARR
while IFS=: read user uid pass acc_type; do
  if [ -n "${user}" ] && [ -n "${pass}" ]; then
    /scripts/recreate_user.sh $user $uid $pass $acc_type
  fi
  FTP_USER_TYPES_ARR[$user]=$acc_type
done < ${PRIVATE_SECRETS_PATH}/ftp_users

# /scripts/permission_groups.sh
/scripts/assign_groups.sh

# it is mandatory to have the a4e user in the secrets

mkdir -p -m 750 ${A4E_USER_HOME}/.ssh/
cp ${AUTHORIZED_SECRETS_PATH}/a4e ${A4E_USER_HOME}/.ssh/authorized_keys
chown -R ${A4E_USER}:${A4E_USER} ${A4E_USER_HOME}/.ssh

# crontab /scripts/jobs.crontab
# crond

mkdir /run/sshd
umask 007
exec /usr/sbin/sshd -D -h ${PRIVATE_SECRETS_PATH}/host_key_rsa -p ${SFTP_PORT}
# Seems like we need to be root, since UsePrivilegeSeparation cannot be used when running sshd as non-root user