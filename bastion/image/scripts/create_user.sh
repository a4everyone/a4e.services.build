#! /bin/bash

# !!!!ATTENTION!!! NEVER EVER CHANGE UID-s OR GID-s in the secrets file, as this will lead to catastrophic
# consequences like clients being able to access othere clients' data!!!
# 
# Following are some basic conventions of the user, group and directory management:
#
# COMMON GROUNDS:
# You can't get access to a colleague's home directory. You can't be a member of your colleague's main group
# Each A4E employee is a member of the a4e_internal group. It gives them read/write access to the ${USER}/.internal folders for all employee users.
# Becoming a member of a client's main group gives you read-only access to their home dir and read/write access to their home/.shared dir
# Becoming a member of a client's internal group gives you read/write access to their home/.internal dir
#
##############################################
# CLIENT USERNAMES AND DIRECTORY CONVENTIONS #
##############################################
#
# N.B.: XYZ is the 3-symbol abbreviation of the client; USER=cli_XYZ
# 
# The main user group is named like the user, so we refer to it by ${USER}
# The {$USER_HOME} directory is naturally owned by ${USER}:${USER}. This directory and all its subdirectory, except the ones listed below, 
#       are used for one-way communication from the client to A4E.
#       Its permission is rwx|r-s|---, as well as that of nested files and directories.
#       OS convention rules that a ${USER_HOME} directory should not be readable gy the group, nor others
#
# The {$USER_HOME}/.shared directory is used for two-directional communication with the client.
#       The ${USER}:${USER} owns this directory and is set as the default gid for new files and subdirectories.
#       Its permission is rwx|rws|---, as well as that of nested files and directories.
#
# The {$USER_HOME}/.internal directory is for two-directional communication between A4E employees, regarding the client, that is not visible to the client.
#       The a4e:${USER}_internal group owns this directory and is set as the default gid for new files and subdirectories.
#       Its permission is rwx|rws|---, as well as that of nested files and directories.
#
####################################################
# A4E EMPLOYEE USERNAMES AND DIRECTORY CONVENTIONS #
####################################################
#
# ${USER} is the linux username of the A4E employee
# The main user group is named like the user, so we refer to it by ${USER}
# The {$USER_HOME} directory is naturally owned by ${USER}:${USER}. This folder and all its subfolders, except the ones listed below, are private to the ${USER}.
#       Its The permission is rwx|r-s|r-x, but its nested files and directories have rwx|r-s|---. We need o+rx for the rest of the a4e employees to be able to list the user folders in their sftp clients
# The {$USER_HOME}/.internal directory is used for two-directional communication with A4E employees. It is not visible to any client.
#       a4e:a4e_internal owns this directory and is set as the default gid for new files and subdirectories.
#       Its permissions are rwx|rwx|0, same as nested files/directories

set -e

source /scripts/bootstrap.sh

# After this umask, new files and folders don't give privileges to "other".
umask 007

# user=cli_rwe
# uid=1112
# user_type=cli a4e a5e
user=$1
uid=$2
pass="$3"
user_type=$4
auth_key=$5

user_home=/home/ftp_users/${user}


CRITICAL_ERRORS=""
#Find out the a4e UID, as it is assumed this is the lowest UID for all SFTP users.
a4e_user_uid=$(id -u ${A4E_USER} 2> /dev/null)
if [ -z "${a4e_user_uid}" ]; then 
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The primordial user \"${A4E_USER}\" was not found."
fi

# Calculate the reserved guid-s by the formula 43000 + ($uid - $a4e_user_uid) * 5
# The following assumptions and constraints take place here:
# Constraint: max UID and GUID is 256000, this is a system limitation.
# Constraint: UID/GUID range 1002 - 1100 are system reserved. GUID 1002 is the a4e_internal group, UID/GUID 1100 is for clearlypro
# Constraint: UID/GUID range 1010 - 1060 are clearance level groups that give access to specific keys. For more details check permission_groups.sh in this directory.
# Constraint: employee accounts have UID/GUID range 1101 - 5100
# Constraint: client   accounts have UID/GUID range 5100 - 42999 (god bless my optimism)
# Assumption: At its peak, A4E Corp. will have 37,899 clients and 3999 employees. We leave 5 reserved gids for each main gid.
# Assumption: ${A4E_USER} has the lowest UID of all the ftp users and it is 1001.
# Given these, the last 5 reserved GUIDs would be 252,990 : 252,994, which is just below the OS limit of 256,000
#
# Reserved GUID 1/5 is for ${user}_internal group, where only a4e employees can be members.
gr_internal_guid=$(( 43000 + ($uid - $a4e_user_uid) * 5 ))

# Produce even more important "global" variables to use:
set +e # The below commands return errors when a user/group doesn't exist
curr_uid=$(id -u ${user} 2> /dev/null) # The user's current UID, empty if there is no such user
curr_guid=$(getent group ${user} | cut -d: -f3) # The user's main group's current GUID, empty if there is no such group
gr_internal="${user}_internal" # The name of the a4e internal access group, for both client and employee accounts
gr_internal_curr_guid=$(getent group ${gr_internal} | cut -d: -f3)
dir_shared=".shared"
dir_internal=".internal"
dir_keyvault=".vault"
set -e # Reset the error flag

# Execute some checks before creating users/groups
if [ -n "$curr_uid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* User ${user} already exists with uid ${curr_uid}"
fi
if [ -n "$curr_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* Group ${user} already exists with uid ${curr_guid}"
fi
# Check for ${USER}_internal group, when this is a client account
if [ "$user_type" == "cli" ] && [ -n "$gr_internal_curr_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* Group ${gr_internal} already exists with uid ${gr_internal_curr_guid}"
fi
if [ -d ${user_home} ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* User's home dir ${user_home} already exists. For security reasons, this is not supposed to happen!"
fi

if [ -n "$CRITICAL_ERRORS" ]; then
    echo "The following CRITICAL ERRORs were found:"
    echo -e "$CRITICAL_ERRORS"
    echo "User was NOT CREATED! Please resolve the errors before retrying!"
    false
fi

#####################
## Create the user ##
#####################
# The default permissions for the home directory are drwxr-sr-x: 
# "s" means "setGID" flag + executable ("S" means setGID - executable)

# adduser -D ${user} -u ${uid} -h ${user_home} # the busybox (alpine) adduser
adduser --disabled-password --uid ${uid} --home ${user_home} --quiet --gecos "" ${user}
echo "${user}:${pass}" | chpasswd

# Create the .ssh folder if it doesn't exist
if [ ! -d ${user_home}/.ssh ]; then
    mkdir -p ${user_home}/.ssh
fi

if [ -n "$auth_key" ]; then
    echo $auth_key > ${user_home}/.ssh/authorized_keys
else
    touch ${user_home}/.ssh/authorized_keys
fi

# Create the {user}_internal group if it doesn't exist
if [ "$user_type" == "cli" ]; then
    # addgroup -g ${gr_internal_guid} ${gr_internal} # the busybox (alpine) addgroup
    addgroup --gid ${gr_internal_guid} ${gr_internal}
    mkdir -p ${user_home}/${dir_shared}

    # Add A4E_USER in the newly created group(s)
    adduser $A4E_USER ${user}_internal
else
    mkdir -p ${user_home}/${dir_keyvault}
    adduser "${user}" "${A4E_INTERNAL_GROUP}"
    if [[ $user_type == "a5e" ]]; then
        adduser "${user}" "${A4E_USER}"
    fi
fi

adduser $A4E_USER $user

mkdir -p ${user_home}/${dir_internal}

# This is an idempotent function, it won't take any action unless necessary
function mend_file_props {
    path="$1"
    expected_UID=$2
    expected_GID=$3
    expected_PRM=$4

    if [ ! -e $path ]; then
        echo "ERROR while setting the permissions and ownership for ${path}: The file or directory doesn't exist"
        false
    fi

    curr_UID=$(stat -c "%u" "$path")
    curr_GID=$(stat -c "%g" "$path")
    curr_PRM=$(stat -c "%a" "$path")

    if [ "$expected_PRM" -ne "$curr_PRM" ]; then
        echo "Changing permissions for ${path} from $curr_PRM to $expected_PRM"
        chmod $expected_PRM "$path"
    fi

    if [ "$expected_UID" -ne "$curr_UID" ]; then
        echo "Changing user ownership for ${path} from $curr_UID to $expected_UID"
        chown $expected_UID "$path"
    fi

    if [ "$expected_GID" -ne "$curr_GID" ]; then
        echo "Changing group ownership for ${path} from $curr_GID to $expected_GID"
        chgrp $expected_GID "$path"
    fi
}

# The automatically created user_home doesn't obey the umask, so we remove any "other" privileges
if [ "$user_type" == "cli" ]; then
    mend_file_props ${user_home} ${uid} ${uid} 2750
    mend_file_props ${user_home}/${dir_internal} ${a4e_user_uid} ${gr_internal_guid} 2770
    mend_file_props ${user_home}/${dir_shared} ${uid} ${uid} 2770
    setfacl -d -m g::rx ${user_home}
    setfacl -d -m o::0 ${user_home}
    setfacl -d -m g::rwx ${user_home}/${dir_internal}
    setfacl -d -m o::0 ${user_home}/${dir_internal}
    setfacl -d -m g::rwx ${user_home}/${dir_shared}
    setfacl -d -m o::0 ${user_home}/${dir_shared}
else
    mend_file_props ${user_home} ${uid} ${uid} 2755
    mend_file_props ${user_home}/${dir_internal} ${a4e_user_uid} ${A4E_INTERNAL_GUID} 2770
    mend_file_props ${user_home}/${dir_keyvault} ${a4e_user_uid} ${uid} 2750
    setfacl -d -m g::rx ${user_home}
    setfacl -d -m o::0 ${user_home}
    setfacl -d -m g::rwx ${user_home}/${dir_internal}
    setfacl -d -m o::0 ${user_home}/${dir_internal}
    setfacl -d -m g::rwx ${user_home}/${dir_keyvault}
    setfacl -d -m o::0 ${user_home}/${dir_keyvault}
fi
mend_file_props ${user_home}/.ssh ${uid} ${uid} 2750
mend_file_props ${user_home}/.ssh/authorized_keys ${uid} ${uid} 400 # authorized_keys needs to be only readable to the user themself, and not writable. Otherwise publickey login doesn't work.

#Preserve the changes for the next time we restart the pod
cp -fPp /etc/passwd /etc/shadow /etc/group $USER_META_PATH/

echo "Done!"
