# Convert input config variables as convenient associative arrays
export PRIVATE_SECRETS_PATH=${PRIVATE_SECRETS_PATH:-"/secrets/private"}
export AUTHORIZED_SECRETS_PATH=${AUTHORIZED_SECRETS_PATH:-"/secrets/authorized"}

declare -A CNF_INT_SERVICE_GROUPS_ARR
for f in $CNF_INT_SERVICE_GROUPS; do CNF_INT_SERVICE_GROUPS_ARR[${f%%=*}]=${f#*=}; done
echo ${CNF_INT_SERVICE_GROUPS_ARR[@]}
declare -A CNF_INT_SERVICE_ACCESS_ARR
for f in $CNF_INT_SERVICE_ACCESS; do CNF_INT_SERVICE_ACCESS_ARR[${f%%=*}]=${f#*=}; done
echo ${CNF_INT_SERVICE_ACCESS_ARR[@]}
declare -A CNF_FTP_CLI_ACCESS_ARR
for f in $CNF_FTP_CLI_ACCESS; do CNF_FTP_CLI_ACCESS_ARR[${f%%=*}]=${f#*=}; done
echo ${CNF_FTP_CLI_ACCESS_ARR[@]}

declare -A USER_TYPES_ARR
declare -A USER_UIDS_ARR
while IFS=: read user uid pass acc_type; do
  USER_TYPES_ARR[$user]=$acc_type
  USER_UIDS_ARR[$user]=$uid
done < ${PRIVATE_SECRETS_PATH}/ftp_users


export A4E_INTERNAL_GUID=1002
export A4E_INTERNAL_GROUP=a4e_internal
