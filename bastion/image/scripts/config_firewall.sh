#! /bin/bash

source /scripts/bootstrap.sh

iptables --new-chain a4e_int
iptables --new-chain a4e_god
iptables --new-chain a4e_cli
iptables --flush a4e_int
iptables --flush a4e_cli
iptables --flush OUTPUT

# Allow all traffic for root
iptables -A OUTPUT -m owner --uid-owner 0 -j ACCEPT
# Allow all traffic for apt
iptables -A OUTPUT -m owner --uid-owner 100 -j ACCEPT
# Allow all traffic for user a4e
iptables -A OUTPUT -m owner --uid-owner ${A4E_USER_UID} -j a4e_god

# Allow internal services traffic for listed users only

# Give service access to all current and future employees
for uid in $(seq $MIN_EMPLOYEE_UID $MAX_EMPLOYEE_UID); do
    iptables -A OUTPUT -m owner --uid-owner ${uid} -j a4e_int
done

# Reject everything else
iptables -A OUTPUT -j REJECT

# Make the chain that allows access to all internal services but cuts everything else
# The list of internal services should ideally be in a configuration, so that when a new service appears we wouldn't need to rebuild this image
TAB_CHAR=$(echo -e "\t")
while IFS=$TAB_CHAR read dest protocol dport; do
    if [[ ! $dest =~ \#.* ]] && [ -n "$dest" ]; then # skipping rows that start with # and empty rows
        echo "Trying iptables on dest: $dest protocol: $protocol dport: $dport"
        iptables -A a4e_int --src ${HOSTNAME} --dest $dest --protocol $protocol --dport $dport -j ACCEPT
        # iptables -A a4e_int --src ${HOSTNAME} --dest kube-dns.kube-system.svc.cluster.local --protocol udp --dport 53 -j ACCEPT # The DNS service, we can't resolve hostnames without it.
        # iptables -A a4e_int --src ${HOSTNAME} --dest cd-pypiserver.cd.svc.cluster.local --protocol tcp --dport 8080 -j ACCEPT
        # iptables -A a4e_int --src ${HOSTNAME} --dest cd-docker-registry.cd.svc.cluster.local --protocol tcp --dport 5000 -j ACCEPT
        # iptables -A a4e_int --src ${HOSTNAME} --dest af-web.af.svc.cluster.local --protocol tcp --dport 8080 -j ACCEPT
        # iptables -A a4e_int --src ${HOSTNAME} --dest af-flower.af.svc.cluster.local --protocol tcp --dport 5555 -j ACCEPT
    fi
done < ${USER_META_PATH}/firewall_employee_accepts
iptables -A a4e_int -j REJECT

iptables -A a4e_cli -j REJECT

iptables -A a4e_god -j ACCEPT

# Some day, when iptables doesn't allow all employees to have access to all services, use
# iptables-save
# to store the setup, and then restore it upon restart with
# iptables-restore
# This will also require a separate job to change network permissions for users, as the main container in this pod doesn't have the NET_ADMIN capability.
# Either this, or just restarting the pod would suffice too, albeit uglier

# apt install net-tools iputils-ping curl # for ifconfig

iptables-save > ${USER_META_PATH}/firewall_employee_accepts.iptables # Not really used for now, but just in case