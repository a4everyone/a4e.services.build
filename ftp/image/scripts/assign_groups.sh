#! /bin/sh

set -e

addgroup $A4E_USER $A4E_INTERNAL_GROUP
# First we collect all employee users
# In this loop we also add A4E_USER as a member of all groups - main user groups and internal client groups.
# Note: this is classic shell, so no actual arrays, no <<< redirecting from variable, no nothing
empl_users=""
# Elevated users are the ones that are members of the a4e group, giving them access to the azure-volume-service-folders in /home/a4e
# Elevated users are also employee accounts, obeying the normal employee acc permissions for client access
elev_users=""
while IFS=: read user uid pass acc_type; do
    if [ -n "${user}" ]; then
        addgroup $A4E_USER $user
        if [ "$acc_type" == "cli" ]; then
            addgroup $A4E_USER ${user}_internal
        else
            empl_users="$empl_users\n$user"
            if [ "$acc_type" == "a5e" ]; then
                elev_users="$elev_users\n$user"
            fi
        fi
    fi
done < /run/secrets/ftp_users
empl_users="$empl_users\n" # Adding a trailing \n, so that later inclusion checks all conform to the regex \nNAME\n
elev_users="$elev_users\n"

# Delete all supplementary groups for every employee acc - we'll add back the needed ones later in this script
for empl_usr in $( echo -e "$empl_users" ); do
    suppl_grps=$( id -Gn ${empl_usr} )
    main_grp=$( id -gn ${empl_usr} )

    for grp_to_del in $( echo $suppl_grps | tr " " "\n" ); do
        if [ $grp_to_del != $main_grp ] && [ $grp_to_del != "${main_grp}_shared" ]; then
            echo "Removing supplementary group \"${grp_to_del}\" for \"${empl_usr}\""
            delgroup $empl_usr $grp_to_del
        fi
    done
done

# Next we add all employees to the a4e_internal group
for empl_usr in $(echo -e "$empl_users"); do
    echo "assigning group ${A4E_INTERNAL_GROUP} to ${empl_usr}"
    addgroup "${empl_usr}" "${A4E_INTERNAL_GROUP}"
done

# Next we add the elevated employees to the a4e group
for elev_usr in $(echo -e "$elev_users"); do
    echo "assigning group ${A4E_USER} to elevated user ${elev_usr}"
    addgroup "${elev_usr}" "${A4E_USER}"
done

# Adding the client and client_internal groups where necessary
while IFS=":" read user groups; do
    if [ -n "${groups}" ]; then
        groups=$( echo $groups | tr "," "\n" )
        for grouptoadd in ${groups}; do
            # if [ -z "${empl_users##*\\n${grouptoadd}\\n*}" ]; then # This twisted condition is just a check if ${empl_users} contains ${grouptoadd}
            #     # This is an a4e employee group assigned
            # fi
            echo "assigning group ${grouptoadd} to ${user}"
            addgroup "${user}" "${grouptoadd}"
            addgroup "${user}" "${grouptoadd}_internal"
        done
    fi

done <<EOF
$( echo $CNF_FTP_CLI_ACCESS | tr " " "\n" )
EOF
