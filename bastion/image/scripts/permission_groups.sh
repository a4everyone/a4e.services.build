#! /bin/bash
# 1010 - 1060
set -e

PERM_GROUPS="
p_mongo_prod_root=1010
p_mongo_prod_app=1011
p_mongo_stage_root=1012
p_mongo_stage_app=1013
p_vpnt_prod=1014
p_vpnt_stage=1015
p_deploy_prod=1016
p_deploy_stage=1017
p_azure_prod=1018
p_azure_stage=1019"

for perm in $PERM_GROUPS; do
    THISGR=${perm%=*}
    THISGID=${perm#*=}
    # Check if the group exists and has the same gid as expected
    curr_guid=$(getent group $THISGR | cut -d: -f3)
    if [ -n "$curr_guid" ] && [ "$curr_guid" -ne "$THISGID" ]; then
        echo "CRITICAL: The current GUID for group ${THISGR} is ${curr_guid}, but the configuration says it should be ${THISGID}."
        echo "The system will not start due to the above critical error"
        false
    fi
    # Create the group if it doesn't exist
    if [ -z "$curr_guid" ]; then
        echo "Creating group ${THISGR}:${THISGID}"
        addgroup -gid ${THISGID} ${THISGR}
    else
        echo "Group ${THISGR}:${THISGID} already exists"
    fi
done
