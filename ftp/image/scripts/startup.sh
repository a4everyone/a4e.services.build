#! /bin/sh
# Making sure the local volume has prоper privileges at runtime.
chmod o-r /
chmod 771 /home/ftp_users
chown root:${A4E_USER} /home/ftp_users

set -e

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
