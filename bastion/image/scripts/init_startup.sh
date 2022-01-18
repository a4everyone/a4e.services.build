#! /bin/bash

set -e

source /scripts/bootstrap.sh

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

adduser $A4E_USER $A4E_INTERNAL_GROUP

if [ ! -d $USER_META_PATH ]; then
    mkdir -p $USER_META_PATH
    chmod 750 $USER_META_PATH
fi
if [ ! -r $USER_META_PATH/passwd ]; then
    cp -fpP /etc/passwd $USER_META_PATH/
fi
if [ ! -r $USER_META_PATH/shadow ]; then
    cp -fpP /etc/shadow $USER_META_PATH/
fi
if [ ! -r $USER_META_PATH/group ]; then
    cp -fpP /etc/group $USER_META_PATH/
fi

if [ ! -r ${USER_META_PATH}/firewall_employee_accepts ]; then
    echo '
# These are the kube services a4e employees have access to.
# This is a tab-separated list with # for comments.
kube-dns.kube-system.svc.cluster.local	udp	53
' > ${USER_META_PATH}/firewall_employee_accepts
fi

# sleep 2000

/scripts/config_firewall.sh