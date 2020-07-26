#! /bin/sh
# Making sure the local volume has prоper privileges at runtime.
chmod o-r /
chmod 771 /home/ftp_users
chown root:${A4E_USER} /home/ftp_users

while IFS=: read user pass uid othergroups; do
  if [ -n "${user}" ] && [ -n "${pass}" ]; then
    if [ ! "${user}" == ${A4E_USER} ]; then # A4E_USER is already present, we only need to update its pass. Thus, we skipp all the boilerplate around user creation
      mkdir -p /home/ftp_users/${user}
      adduser -D ${user} -u ${uid} -h /home/ftp_users/${user}
      chown ${user}:${user} /home/ftp_users/${user} # In the unlikely case that we shuffled the UIDs in the secrets - re-chown the persisted volume with the new UID.
      chmod 770 /home/ftp_users/${user}

      # The A4E_USER is by default a member in all ftp-client groups
      addgroup ${A4E_USER} ${user}

      if [ -n "${othergroups}" ]; then
          othergroups=$( echo $othergroups | tr ";" "\n" )
          for grouptoadd in ${othergroups}; do
              addgroup "${user}" "${grouptoadd}"
          done
      fi
    fi
    # Changing pass needs to happen for A4E_USER as well
    echo "${user}:${pass}" | chpasswd
  fi
done < /run/secrets/ftp_users

# it is mandatory to have the a4e user in the secrets

# host keys need to be in dropbear format. OpenSSH isn't compatible.
dropbearconvert openssh dropbear /run/secrets/ftp_host_key_rsa /etc/dropbear/dropbear_rsa_host_key
dropbearconvert openssh dropbear /run/secrets/ftp_host_key_ecdsa /etc/dropbear/dropbear_ecdsa_host_key
mkdir -p -m 770 ${A4E_USER_HOME}/.ssh/
cp /run/secrets/ftp_authorized_pubkey ${A4E_USER_HOME}/.ssh/authorized_keys
#chown ${A4E_USER} ${A4E_USER_HOME}
chown -R ${A4E_USER} ${A4E_USER_HOME}/.ssh

crontab /jobs.crontab
crond

umask 007
exec dropbear -p ${SFTP_PORT} $@
