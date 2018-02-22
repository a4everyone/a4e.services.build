#! /bin/sh

while IFS=: read user pass uid othergroups; do
  if [ -n "${user}" ] && [ -n "${pass}" ]; then
    adduser -D ${user} -u ${uid}
    echo "${user}:${pass}" | chpasswd

    if [ -n "${othergroups}" ]; then
        IFS=';' tokens=( $othergroups )
        for grouptoadd in "${tokens[@]}"; do
            addgroup "${user}" "${grouptoadd}"
        done
    fi

#    addgroup -g ${gid} ${group}
#    adduser ${user} ${group}
  fi
done < /run/secrets/ftp_users

# it is mandatory to have the a4e user in the secrets

# host keys need to be in dropbear format. OpenSSH isn't compatible.
dropbearconvert openssh dropbear /run/secrets/ftp_host_key_rsa /etc/dropbear/dropbear_rsa_host_key
dropbearconvert openssh dropbear /run/secrets/ftp_host_key_ecdsa /etc/dropbear/dropbear_ecdsa_host_key
mkdir -p ${A4E_USER_HOME}/.ssh/
cp /run/secrets/ftp_authorized_pubkey ${A4E_USER_HOME}/.ssh/authorized_keys
chown ${A4E_USER} ${A4E_USER_HOME}
chown -R ${A4E_USER} ${A4E_USER_HOME}/.ssh

exec dropbear -p ${SFTP_PORT} $@
