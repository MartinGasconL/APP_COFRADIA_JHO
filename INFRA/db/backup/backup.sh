#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/backup"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
MONTHLY_DIR="$BACKUP_DIR/monthly"
mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR"

DAILY_KEEP="${DAILY_KEEP:-7}"
WEEKLY_KEEP="${WEEKLY_KEEP:-4}"
MONTHLY_KEEP="${MONTHLY_KEEP:-2}"

DATE="$(date +%Y-%m-%d)"
DOW="$(date +%u)"   # 1=lunes ... 7=domingo
DOM="$(date +%d)"

FILE="aseint_${DATE}.sql.gz"
DUMP_PATH="$DAILY_DIR/$FILE"

mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
  --single-transaction --routines --triggers \
  "$MYSQL_DATABASE" | gzip -9 > "$DUMP_PATH"

# Domingo -> también copia semanal
if [ "$DOW" = "7" ]; then
  cp "$DUMP_PATH" "$WEEKLY_DIR/$FILE"
fi

# Día 1 del mes -> también copia mensual
if [ "$DOM" = "01" ]; then
  cp "$DUMP_PATH" "$MONTHLY_DIR/$FILE"
fi

prune() {
  local dir="$1" keep="$2"
  find "$dir" -maxdepth 1 -name '*.sql.gz' -type f | sort | head -n -"$keep" | xargs -r rm --
}

prune "$DAILY_DIR" "$DAILY_KEEP"
prune "$WEEKLY_DIR" "$WEEKLY_KEEP"
prune "$MONTHLY_DIR" "$MONTHLY_KEEP"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup OK: $FILE"
