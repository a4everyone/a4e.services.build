#! /bin/sh
# Making sure the local volume has prоper privileges at runtime.
chmod o-r /

set -e

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
    addgroup -g ${A4E_INTERNAL_GUID} ${A4E_INTERNAL_GROUP}
fi

chown ${A4E_USER}:${A4E_INTERNAL_GROUP} /home/ftp_users
chmod 751 /home/ftp_users

while IFS=: read user uid pass acc_type; do
  if [ -n "${user}" ] && [ -n "${pass}" ]; then
    /scripts/recreate_user.sh $user $uid $pass $acc_type
  fi
done < /run/secrets/ftp_users
/scripts/assign_groups.sh

# it is mandatory to have the a4e user in the secrets

# host keys need to be in dropbear format. OpenSSH isn't compatible.
dropbearconvert openssh dropbear /run/secrets/ftp_host_key_rsa /etc/dropbear/dropbear_rsa_host_key
dropbearconvert openssh dropbear /run/secrets/ftp_host_key_ecdsa /etc/dropbear/dropbear_ecdsa_host_key
mkdir -p -m 750 ${A4E_USER_HOME}/.ssh/
cp /run/secrets/ftp_authorized_pubkey ${A4E_USER_HOME}/.ssh/authorized_keys
#chown ${A4E_USER} ${A4E_USER_HOME}
chown -R ${A4E_USER}:${A4E_USER} ${A4E_USER_HOME}/.ssh

crontab /scripts/jobs.crontab
crond

umask 007
exec dropbear -p ${SFTP_PORT} $@
