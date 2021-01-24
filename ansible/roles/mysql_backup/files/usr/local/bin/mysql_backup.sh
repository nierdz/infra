#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

DEBUG=${DEBUG:=0}
[[ $DEBUG -eq 1 ]] && set -o xtrace

# Get MySQL credentials
#shellcheck source=/dev/null
source /infra/.env

DB="madrabbit"
MYSQLDUMP=(/usr/bin/mysqldump -u root -p"${MADRABBIT_MYSQL_ROOT_PASSWORD}")
MYSQL=(/usr/bin/mysql -u root -p"${MADRABBIT_MYSQL_ROOT_PASSWORD}")
GZIP="/bin/gzip"
TIME_TO_KEEP="60" # Time in days you want to keep old backups
DATE=$(date +%Y%m%d)
BACKUP_ROOT="/var/backups/mysql"
BACKUP_DIR="$BACKUP_ROOT/$DATE"
DOCKER=(/usr/bin/docker exec madrabbit-mysql)
DOCKERI=(/usr/bin/docker exec -i madrabbit-mysql)

# Create backup folder
if [ ! -d "${BACKUP_DIR}" ]; then
  mkdir -p "${BACKUP_DIR}"
fi

# Dump databases
"${DOCKER[@]}" "${MYSQLDUMP[@]}" --opt --routines --events "${DB}" >"${BACKUP_DIR}/${DB}.sql"

# Create temporary databases to check dumps
"${DOCKER[@]}" "${MYSQL[@]}" --silent -e "CREATE DATABASE \`${DB}${DATE}\`;"

# Restore dumps in temporary databases
"${DOCKERI[@]}" "${MYSQL[@]}" "${DB}${DATE}" <"${BACKUP_DIR}/${DB}.sql"

# Drop temporary databases
"${DOCKER[@]}" "${MYSQL[@]}" --silent -e "DROP DATABASE \`$DB$DATE\`;"

# Gzip dumps
${GZIP} -f "${BACKUP_DIR}/${DB}.sql"

DB="nextcloud"
MYSQLDUMP=(/usr/bin/mysqldump)
MYSQL=(/usr/bin/mysql)

# Dump databases
"${MYSQLDUMP[@]}" --opt --routines --events "${DB}" >"${BACKUP_DIR}/${DB}.sql"

# Create temporary databases to check dumps
"${MYSQL[@]}" --silent -e "CREATE DATABASE \`${DB}${DATE}\`;"

# Restore dumps in temporary databases
"${MYSQL[@]}" "${DB}${DATE}" <"${BACKUP_DIR}/${DB}.sql"

# Drop temporary databases
"${MYSQL[@]}" --silent -e "DROP DATABASE \`$DB$DATE\`;"

# Gzip dumps
${GZIP} -f "${BACKUP_DIR}/${DB}.sql"

# Delete old backups
find "${BACKUP_ROOT}" -type d -mtime +"${TIME_TO_KEEP}" -exec rm -rf {} \;
