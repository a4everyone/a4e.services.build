#! /bin/bash

set -e

source /scripts/bootstrap.sh

user=$1
groups=$2

# Delete all supplementary groups for every employee acc - we'll add back the needed ones later in this script
for empl_usr in $( echo -e "$empl_users" ); do
    suppl_grps=$( id -Gn ${empl_usr} )
    main_grp=$( id -gn ${empl_usr} )

    for grp_to_del in $( echo $suppl_grps | tr " " "\n" ); do
        if [ $grp_to_del != $main_grp ] && [ $grp_to_del != "${main_grp}_shared" ]; then
            echo "Removing supplementary group \"${grp_to_del}\" for \"${empl_usr}\""
            deluser $empl_usr $grp_to_del
        fi
    done
done

curr_uid=$(id -u ${user} 2> /dev/null)
if [ -z $curr_uid ]; then
    echo "ERROR: User ${user} not found!"
    false
fi

groups=$( echo $groups | tr "," "\n" )
for grouptoadd in ${groups}; do
    adduser "${user}" "${grouptoadd}"
    adduser "${user}" "${grouptoadd}_internal"
done

#Preserve the changes for the next time we restart the pod
cp -fPp /etc/passwd /etc/shadow /etc/group $USER_META_PATH/

echo "Done!"
