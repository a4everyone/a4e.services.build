#! /bin/sh

# !!!!ATTENTION!!! NEVER EVER CHANGE UID-s OR GID-s in the secrets file, as this will lead to catastrophic
# consequences like clients being able to access othere clients' data!!!
# 
# Following are some basic conventions of the user, group and directory management:
#
# COMMON GROUNDS:
# You can't get access to a colleague's private directory. You can't be a member of your colleague's main group
# If you need access to a colleague's shared directory, you need to be a member into their ${USER}_shared group
# If you need to access a client's home directory, you need to be a member of their main group
# If you need to access a client's shared directory, you need to be a member of their {USER}_shared group
# If you need to access a client's private directory, you need to be a member of their {USER}_private group
#
##############################################
# CLIENT USERNAMES AND DIRECTORY CONVENTIONS #
##############################################
#
# N.B.: XYZ is the 3-symbol abbreviation of the client; USER=cli_XYZ
# 
# The main user group is named like the user, so we refer to it by ${USER}
# The {$USER_HOME} directory is naturally owned by ${USER}:${USER}. This directory and all its subdirectory, except the ones listed below, 
#       are used for one-way communication from the client to A4E. Its permission, is rwx|r-s|---.
#       OS convention rules that a ${USER_HOME} directory should not be readable gy the group, not others
#
# The {$USER_HOME}/${USER}_shared directory is used for two-directional communication with the client.
#       The ${USER}_shared group owns this directory and is set as the default gid for new files and subdirectories.
#
# The {$USER_HOME}/${USER}_private directory is for two-directional communication between A4E employees, regarding the client, that is not visible to the client.
#       The ${USER}_private group owns this directory and is set as the default gid for new files and subdirectories.
#
####################################################
# A4E EMPLOYEE USERNAMES AND DIRECTORY CONVENTIONS #
####################################################
#
# ${USER} is the linux username of the A4E employee
# The main user group is named like the user, so we refer to it by ${USER}
# The {$USER_HOME} directory is naturally owned by ${USER}:${USER}. This folder and all its subfolders, except the ones listed below, 
#       are private to the ${USER}. Its permission, is rwx|--s|---.
#       OS convention rules that a ${USER_HOME} directory should not be readable gy the group, not others
# The {$USER_HOME}/${USER}_shared directory is used for two-directional communication with A4E employees. It is not viusible to any client.
#       The ${USER}_shared group owns this directory and is set as the default gid for new files and subdirectories.

set -e

# After this umask, new files and folders don't give privileges to "other".
umask 007

user=cli_rwe
uid=1112
user_type=cli # other possible option is a4e
user_home=/home/ftp_users/${user}


CRITICAL_ERRORS=""
#Find out the a4e UID, as it is assumed this is the lowest UID for all SFTP users.
a4e_user_uid=$(id -u ${A4E_USER} 2> /dev/null)
if [ -z "${a4e_user_uid}" ]; then 
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The primordial user \"${A4E_USER}\" was not found."
fi

# Calculate the shared_guid and private_guid by the formula 43000 + ($uid - $a4e_user_uid) * 5
# The following assumptions and constraints take place here:
# Constraint: max UID and GUID is 256000, this is a system limitation.
# Assumption: At its peak, A4E Corp. will have 42,999 clients. We leave 5 reserved gids for each main gid.
# Assumption: ${A4E_USER} has the lowest UID of all the ftp users and it is 1001.
# Given these, the last 5 reserved GUIDs would be 252,990 : 252,994, which is just below the OS limit of 256,000
#
# Reserved GUID 1/5 is for ${user}_shared group, for both client and employee accounts.
# Reserved GUID 2/5 is for ${user}_private group, for client accounts. It is not used for employee accounts
shared_guid=$(( 43000 + ($uid - $a4e_user_uid) * 5 ))
if [ "$user_type" == "cli" ]; then
    private_guid=$(( $shared_guid + 1 ))
fi

# Produce even more important "global" variables to use:
set +e # The below commands return errors when a user/group doesn't exist
curr_uid=$(id -u ${user} 2> /dev/null) # The user's current UID, empty if there is no such user
curr_guid=$(getent group ${user} | cut -d: -f3) # The user's main group's current GUID, empty if there is no such group
gr_shared="${user}_shared" # The name of the shared group, for both client and employee accounts
gr_private="${user}_private" # The name of the private group, for client accounts
gr_shared_curr_guid=$(getent group ${gr_shared} | cut -d: -f3)
gr_private_curr_guid=$(getent group ${gr_private} | cut -d: -f3)
set -e # Reset the error flag

# Execute some checks before creating users/groups
if [ -n "$curr_uid" ] && [ "$curr_uid" -ne "$uid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current UID for user ${user} is ${curr_uid}, but the configuration says it should be ${uid}."
fi

if [ -n "if [ -n "$curr_guid" ] && [ "$curr_guid" -ne "$uid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current GUID for group ${user} is ${curr_guid}, but the configuration says it should be ${uid}."
fi
" ] && [ "$curr_guid" -ne "$uid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current GUID for group ${user} is ${curr_guid}, but the configuration says it should be ${uid}."
fi

if [ -z "$curr_uid" ] && [ -n "$curr_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* There is only a group \"${user}\" but no user \"${user}\" created. The user creation will fail."
elif [ -n "$curr_uid" ] && [ -z "$curr_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* There is only a user \"${user}\" but no group \"${user}\" created. The user creation will fail."
# elif [ -z $curr_uid ] && [ -z $curr_guid ]; then # No such user and group in the system, no further checks needed
fi

# Check for ${USER}_shared group
if [ -n "$gr_shared_curr_guid" ] && [ "$gr_shared_curr_guid" -ne "$shared_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current GUID for group ${gr_shared} is ${gr_shared_curr_guid}, but the configuration says it should be ${shared_guid}."
fi

# Check for ${USER}_private group, when this is a client account
if [ "$user_type" == "cli" ] && [ -n "$gr_private_curr_guid" ] && [ "$gr_private_curr_guid" -ne "$private_guid" ]; then
    CRITICAL_ERRORS="${CRITICAL_ERRORS}\n\t* The current GUID for group ${gr_private} is ${gr_private_curr_guid}, but the configuration says it should be ${private_guid}."
fi

if [ -n "$CRITICAL_ERRORS" ]; then
    echo "The following CRITICAL ERRORs were found. The system won't start until you resolve them:"
    echo -e "$CRITICAL_ERRORS"
fi

# For the sake of data leak prevention, this SFTP server won't start until you resolve the situation!!!

# Create the user, if it doesn't exist
if [ -z "$curr_uid" ]; then # empty curr_uid means user doesn't exist
    # The default permissions for the home directory are drwxr-sr-x: 
    # "s" means "setGID" flag + executable ("S" means setGID - executable)
    adduser -D ${user} -u ${uid} -h ${user_home}
    # The automatically created user_home doesn't obey the umask, so we remove any "other" privileges
    if [ "$user_type" == "cli" ]; then
        chmod 750 ${user_home}
        chmog g+s ${user_home}
    else
        chmod 710 ${user_home}
        chmog g+s ${user_home}
    fi
fi
# Create the .ssh folder if it doesn't exist
if [ ! -d ${user_home}/.ssh ]; then
    mkdir -p ${user_home}/.ssh
    chown ${user}:${user} ${user_home}/.ssh
    chmod g-w ${user_home}/.ssh
fi
# Create the .ssh/authorized_keys if it doesn't exist
if [ ! -f ${user_home}/.ssh/authorized_keys ]; then
    touch ${user_home}/.ssh/authorized_keys
    chown ${user}:${user} ${user_home}/.ssh/authorized_keys
    # authorized_keys needs to be only readable to the user themself, and not writable. Otherwise it doesn't work.
    chmod 400 ${user_home}/.ssh/authorized_keys
fi

# Create the {user}_shared group if it doesn't exist
if [ -z "$gr_shared_curr_guid" ]; then
    addgroup -g ${shared_guid} ${gr_shared}
fi
# Create the {user}_private group if it doesn't exist
if [ "$user_type" == "cli" ] && [ -z "$gr_private_curr_guid" ]; then
    addgroup -g ${private_guid} ${gr_private}
fi

# Create the ${user_home}/${gr_shared} dir if it doesn't exist
if [ ! -d ${user_home}/${gr_shared} ]; then
    mkdir -p ${user_home}/${gr_shared}
    chown ${user}:${gr_shared} ${user_home}/${gr_shared}
    chmod 770 ${user_home}/${gr_shared}
    chmod g+s ${user_home}/${gr_shared}
fi

if [ "$user_type" == "cli" ] && [ ! -d ${user_home}/${gr_private} ]; then
    mkdir -p ${user_home}/${gr_private}
    chown ${A4E_USER}:${gr_private} ${user_home}/${gr_private}
    chmod 770 ${user_home}/${gr_private}
    chmod g+s ${user_home}/${gr_private}
fi