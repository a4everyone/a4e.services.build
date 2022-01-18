#! /bin/bash

set -e

source /scripts/bootstrap.sh

user=$1
groups=$2

curr_uid=$(id -u ${user} 2> /dev/null)
if [ -z $curr_uid ]; then
    echo "ERROR: User ${user} not found!"
    false
fi

groups=$( echo $groups | tr "," "\n" )
for grouptodel in ${groups}; do
    deluser "${user}" "${grouptodel}"
    deluser "${user}" "${grouptodel}_internal"
done

#Preserve the changes for the next time we restart the pod
cp -fPp /etc/passwd /etc/shadow /etc/group $USER_META_PATH/

echo "Done!"
