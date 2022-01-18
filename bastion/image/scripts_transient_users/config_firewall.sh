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
for perm in $CNF_INT_SERVICE_ACCESS; do
    user=${perm%%=*}
    svcs=${perm#*=}
    echo $user
    for svc in $(tr , "\n" <<< $svcs); do
        if [ $svc == "a4e-internal" ]; then
            iptables -A OUTPUT -m owner --uid-owner ${USER_UIDS_ARR[$user]} -j a4e_int
        fi
    done
done
# Reject everything else
iptables -A OUTPUT -j REJECT

# Make the chain that allows access to all internal services but cuts everything else
# The list of internal services should ideally be in a configuration, so that when a new service appears we wouldn't need to rebuild this image
iptables -A a4e_int --src ${HOSTNAME} --dest kube-dns.kube-system.svc.cluster.local --protocol udp --dport 53 -j ACCEPT # The DNS service, we can't resolve hostnames without it.
iptables -A a4e_int --src ${HOSTNAME} --dest cd-pypiserver.cd.svc.cluster.local --protocol tcp --dport 8080 -j ACCEPT
iptables -A a4e_int --src ${HOSTNAME} --dest cd-docker-registry.cd.svc.cluster.local --protocol tcp --dport 5000 -j ACCEPT
iptables -A a4e_int --src ${HOSTNAME} --dest af-web.af.svc.cluster.local --protocol tcp --dport 8080 -j ACCEPT
iptables -A a4e_int --src ${HOSTNAME} --dest af-flower.af.svc.cluster.local --protocol tcp --dport 5555 -j ACCEPT
iptables -A a4e_int -j REJECT

iptables -A a4e_cli -j REJECT

iptables -A a4e_god -j ACCEPT


# apt install net-tools iputils-ping curl # for ifconfig
