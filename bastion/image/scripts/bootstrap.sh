
# Convert input config variables as convenient associative arrays
export PRIVATE_SECRETS_PATH=${PRIVATE_SECRETS_PATH:-"/secrets/private"}
export AUTHORIZED_SECRETS_PATH=${AUTHORIZED_SECRETS_PATH:-"/secrets/authorized"}
export USER_META_PATH="/home/ftp_users/.meta"

export A4E_INTERNAL_GUID=1002
export A4E_INTERNAL_GROUP=a4e_internal

# Read doc/conventions.MD for explanation of these "magic" numbers
export MIN_EMPLOYEE_UID=1101
export MAX_EMPLOYEE_UID=1151 # Theoretical max value here is 5100, but for perf reasons we keep it close to the real employee number