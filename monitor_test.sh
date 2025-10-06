#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
STATE_FILE="/var/run/test_monitor.pid"
URL="https://test.com/monitoring/test/api"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

CURRENT_PID=$(pgrep -o test)

if [ -z "$CURRENT_PID" ]; then
    exit 0
fi

PREVIOUS_PID=""
if [ -f "$STATE_FILE" ]; then
    PREVIOUS_PID=$(cat "$STATE_FILE")
fi

if [ -n "$PREVIOUS_PID" ] && [ "$PREVIOUS_PID" != "$CURRENT_PID" ]; then
    log_message "Процесс 'test' перезапущен: предыдущий PID $PREVIOUS_PID, новый PID $CURRENT_PID"
fi

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$RESPONSE" -lt 200 ] || [ "$RESPONSE" -gt 299 ]; then
    log_message "Сервер мониторинга недоступен: HTTP статус $RESPONSE"
fi

echo "$CURRENT_PID" > "$STATE_FILE"

exit 0