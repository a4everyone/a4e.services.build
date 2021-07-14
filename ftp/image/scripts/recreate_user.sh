#! /bin/sh

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

# After this umask, new files and folders don't give privileges to "other".
umask 007

# user=cli_rwe
# uid=1112
# user_type=cli # everything else is considered a4e employee account
user=$1
uid=$2
pass="$3"
user_type=$4

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
# COnstraint: UID/GUID range 1010 - 1060 are clearance level groups that give access to specific keys. For more details check permission_groups.sh in this directory.
# Constraint: employee accounts have UID/GUID range 1101 - 5100
# Constraint: employee accounts have UID/GUID range 5100 - 42999 (god bless my optimism)
# Assumption: At its peak, A4E Corp. will have 37,899 clients and 3999 employees. We leave 5 reserved gids for each main gid.
# Assumption: ${A4E_USER} has the lowest UID of all the ftp users and it is 1001.
# Given these, the last 5 reserved GUIDs would be 252,990 : 252,994, which is just below the OS limit of 256,000
#
# Reserved GUID 1/5 is for ${user}_a4e group, where only a4e employees can be members.
gr_internal_guid=$(( 43000 + ($uid - $a4e_user_uid) * 5 ))

# Produce even more important "global" variables to use:
set +e # The below commands return errors when a user/group doesn't exist
curr_uid=$(id -u ${user} 2> /dev/null) # The user's current UID, empty if there is no such user
curr_guid=$(getent group ${user} | cut -d: -f3) # The user's main group's current GUID, empty if there is no such group
gr_internal="${user}_internal" # The name of the a4e internal access group, for both client and employee accounts
gr_internal_curr_guid=$(getent group ${gr_internal} | cut -d: -f3)
dir_shared=".shared"
dir_internal=".internal"
set -e # Reset the error flag

# Execute some checks before creating users/groups
if [ -n "$curr_uid" ] && [ "$curr_uid" -ne "$uid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current UID for user ${user} is ${curr_uid}, but the configuration says it should be ${uid}."
fi

if [ -n "$curr_guid" ] && [ "$curr_guid" -ne "$uid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current GUID for group ${user} is ${curr_guid}, but the configuration says it should be ${uid}."
fi

if [ -z "$curr_uid" ] && [ -n "$curr_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* There is only a group \"${user}\" but no user \"${user}\" created. The user creation will fail."
elif [ -n "$curr_uid" ] && [ -z "$curr_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* There is only a user \"${user}\" but no group \"${user}\" created. The user creation will fail."
# elif [ -z $curr_uid ] && [ -z $curr_guid ]; then # No such user and group in the system, no further checks needed
fi

# Check for ${USER}_internal group, when this is a client account
if [ "$user_type" == "cli" ] && [ -n "$gr_internal_curr_guid" ] && [ "$gr_internal_curr_guid" -ne "$gr_internal_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current GUID for group ${gr_internal} is ${gr_internal_curr_guid}, but the configuration says it should be ${gr_internal_guid}."
fi

if [ -n "$CRITICAL_ERRORS" ]; then
    echo "The following CRITICAL ERRORs were found:"
    echo -e "$CRITICAL_ERRORS"
    echo "Execution was prematurely terminated - it is not recommended to fun the SFTP server in such an indetermined state, as this may lead to data leaks between clients."
    false
fi

# For the sake of data leak prevention, this SFTP server won't start until you resolve the situation!!!

# Create the user, if it doesn't exist
if [ -z "$curr_uid" ]; then # empty curr_uid means user doesn't exist
    # The default permissions for the home directory are drwxr-sr-x: 
    # "s" means "setGID" flag + executable ("S" means setGID - executable)
    adduser -D ${user} -u ${uid} -h ${user_home}
    echo "${user}:${pass}" | chpasswd
fi
# Create the .ssh folder if it doesn't exist
if [ ! -d ${user_home}/.ssh ]; then
    mkdir -p ${user_home}/.ssh
fi
# Create the .ssh/authorized_keys if it doesn't exist
if [ ! -f ${user_home}/.ssh/authorized_keys ]; then
    touch ${user_home}/.ssh/authorized_keys
fi

# Create the {user}_internal group if it doesn't exist
if [ "$user_type" == "cli" ] && [ -z "$gr_internal_curr_guid" ]; then
    addgroup -g ${gr_internal_guid} ${gr_internal}
fi

# Create the ${user_home}/${dir_shared} dir if it doesn't exist
if [ "$user_type" == "cli" ] && [ ! -d ${user_home}/${dir_shared} ]; then
    mkdir -p ${user_home}/${dir_shared}
fi

if [ ! -d ${user_home}/${dir_internal} ]; then
    mkdir -p ${user_home}/${dir_internal}
fi

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
    setfacl -d -m g::rx ${user_home}
    setfacl -d -m o::0 ${user_home}
    setfacl -d -m g::rwx ${user_home}/${dir_internal}
    setfacl -d -m o::0 ${user_home}/${dir_internal}
fi
mend_file_props ${user_home}/.ssh ${uid} ${uid} 2750
mend_file_props ${user_home}/.ssh/authorized_keys ${uid} ${uid} 400 # authorized_keys needs to be only readable to the user themself, and not writable. Otherwise publickey login doesn't work.
