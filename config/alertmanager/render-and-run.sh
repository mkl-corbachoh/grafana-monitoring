#!/bin/sh
set -eu

escape_sed() {
  printf '%s' "$1" | sed -e 's/[|&\\]/\\&/g'
}

rendered=/tmp/alertmanager.yml

sed \
  -e "s|__ALERT_TELEGRAM_BOT_TOKEN__|$(escape_sed "$ALERT_TELEGRAM_BOT_TOKEN")|g" \
  -e "s|__ALERT_TELEGRAM_CHAT_ID__|$(escape_sed "$ALERT_TELEGRAM_CHAT_ID")|g" \
  -e "s|__ALERT_EMAIL_TO__|$(escape_sed "$ALERT_EMAIL_TO")|g" \
  -e "s|__ALERT_EMAIL_FROM__|$(escape_sed "$ALERT_EMAIL_FROM")|g" \
  -e "s|__ALERT_SMTP_SMARTHOST__|$(escape_sed "$ALERT_SMTP_SMARTHOST")|g" \
  -e "s|__ALERT_SMTP_USERNAME__|$(escape_sed "$ALERT_SMTP_USERNAME")|g" \
  -e "s|__ALERT_SMTP_PASSWORD__|$(escape_sed "$ALERT_SMTP_PASSWORD")|g" \
  /etc/alertmanager/alertmanager.yml > "$rendered"

exec /bin/alertmanager \
  --config.file="$rendered" \
  --storage.path=/alertmanager
