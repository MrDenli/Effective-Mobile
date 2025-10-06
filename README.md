# Мониторинг процесса 'test' в Linux

Этот репозиторий содержит решение для мониторинга процесса с именем `test` в среде Linux. Решение состоит из bash-скрипта и systemd-юнитов, которые обеспечивают выполнение следующих требований:
- Автоматический запуск при старте системы с периодичностью 1 минута.
- Проверка наличия процесса `test`.
- Отправка HTTPS-запроса на `https://test.com/monitoring/test/api`, если процесс запущен.
- Запись в лог `/var/log/monitoring.log` при перезапуске процесса (изменение PID).
- Запись в лог при недоступности сервера мониторинга (HTTP-статус не 200-299).
- Никаких действий, если процесс не запущен.

Решение разработано как тестовое задание для собеседования и соответствует всем указанным требованиям.

## Структура репозитория

- `monitor_test.sh`: Bash-скрипт для мониторинга процесса.
- `monitor-test.service`: Systemd-юнит для запуска скрипта.
- `monitor-test.timer`: Systemd-юнит для периодического выполнения (каждую минуту).
- `README.md`: Этот файл с документацией.

Файлы должны быть размещены в соответствующих системных директориях (см. раздел "Установка").

## Как работает решение

### Логика скрипта (`monitor_test.sh`)

1. **Переменные**:
   - `LOG_FILE="/var/log/monitoring.log"`: Путь к лог-файлу.
   - `STATE_FILE="/var/run/test_monitor.pid"`: Файл для хранения PID процесса.
   - `URL="https://test.com/monitoring/test/api"`: URL для HTTPS-запроса.

2. **Функция логирования**:
   - `log_message()`: Записывает сообщение в лог с временной меткой (формат: `YYYY-MM-DD HH:MM:SS - Сообщение`).

3. **Проверка процесса**:
   - Использует `pgrep -o test` для получения PID самого старого процесса `test`.
   - Если процесс не найден, скрипт завершает работу без действий.

4. **Проверка перезапуска**:
   - Читает предыдущий PID из `STATE_FILE`.
   - Если PID изменился, записывает в лог сообщение о перезапуске (например: "Процесс 'test' перезапущен: предыдущий PID 1234, новый PID 5678").

5. **HTTPS-запрос**:
   - Отправляет запрос с помощью `curl` и проверяет HTTP-статус.
   - Если статус не в диапазоне 200-299, записывает в лог ошибку (например: "Сервер мониторинга недоступен: HTTP статус 404").

6. **Обновление состояния**:
   - Записывает текущий PID в `STATE_FILE`.

7. **Завершение**:
   - Выход с кодом 0.

### Systemd-юниты

- **monitor-test.service**:
  - Определяет сервис для запуска скрипта (`ExecStart=/usr/local/bin/monitor_test.sh`).
- **monitor-test.timer**:
  - Запускает сервис через 1 минуту после загрузки системы (`OnBootSec=1min`).
  - Повторяет запуск каждую минуту (`OnUnitActiveSec=1min`).
  - `Persistent=true` компенсирует пропущенные запуски при выключенной системе.
  - Устанавливается в `WantedBy=timers.target` для автозапуска.

Скрипт минимизирует нагрузку, выполняя действия только при наличии процесса `test`.

## Установка

1. **Клонируйте репозиторий** (или скопируйте файлы):
   ```bash
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   ```

2. **Разместите файлы**:
   - Скрипт в `/usr/local/bin/` (стандартное место для пользовательских скриптов):
     ```bash
     sudo cp monitor_test.sh /usr/local/bin/monitor_test.sh
     ```
   - Systemd-юниты в `/etc/systemd/system/` (обязательная директория для systemd):
     ```bash
     sudo cp monitor-test.service /etc/systemd/system/monitor-test.service
     sudo cp monitor-test.timer /etc/systemd/system/monitor-test.timer
     ```

   **Примечание**: Если скрипт размещается в другой директории (например, `/home/user/scripts/`), обновите `ExecStart` в `monitor-test.service`:
   ```bash
   ExecStart=/home/user/scripts/monitor_test.sh
   ```

3. **Установите права доступа**:
   - Для скрипта:
     ```bash
     sudo chmod +x /usr/local/bin/monitor_test.sh
     ```
   - Для юнитов:
     ```bash
     sudo chmod 644 /etc/systemd/system/monitor-test.service
     sudo chmod 644 /etc/systemd/system/monitor-test.timer
     ```

4. **Создайте лог-файл**:
   ```bash
   sudo touch /var/log/monitoring.log
   sudo chmod 644 /var/log/monitoring.log
   ```
   (Опционально: `sudo chown youruser:yourgroup /var/log/monitoring.log` для изменения владельца.)

5. **Перезагрузите systemd**:
   ```bash
   sudo systemctl daemon-reload
   ```

6. **Активируйте и запустите таймер**:
   ```bash
   sudo systemctl enable monitor-test.timer
   sudo systemctl start monitor-test.timer
   ```

Теперь скрипт будет запускаться каждую минуту.

## Тестирование и отладка

1. **Проверка таймера**:
   ```bash
   systemctl status monitor-test.timer
   ```
   Ожидаемый статус: `active (waiting)` с указанием времени следующего запуска.

2. **Проверка сервиса**:
   ```bash
   systemctl status monitor-test.service
   ```
   Сервис будет `inactive` между запусками, так как выполняется раз в минуту.

3. **Просмотр логов**:
   - Лог-файл:
     ```bash
     cat /var/log/monitoring.log
     ```
   - Логи systemd:
     ```bash
     journalctl -u monitor-test.service -e
     journalctl -u monitor-test.timer -e
     ```

4. **Тестирование перезапуска**:
   - Запустите процесс для теста (например, `sleep 3600 &` и переименуйте в `test`).
   - Убейте процесс (`kill <PID>`) и запустите заново.
   - Проверьте `/var/log/monitoring.log` на запись о перезапуске.

5. **Тестирование сервера**:
   - Если `https://test.com/monitoring/test/api` недоступен, в логе появится ошибка.

6. **Проверка curl**:
   ```bash
   curl -v https://test.com/monitoring/test/api
   ```

## Деинсталляция

1. Остановите и отключите таймер:
   ```bash
   sudo systemctl stop monitor-test.timer
   sudo systemctl disable monitor-test.timer
   ```

2. Удалите файлы:
   ```bash
   sudo rm /usr/local/bin/monitor_test.sh
   sudo rm /etc/systemd/system/monitor-test.service
   sudo rm /etc/systemd/system/monitor-test.timer
   sudo rm /var/log/monitoring.log  # Опционально
   sudo rm /var/run/test_monitor.pid  # Опционально
   ```

3. Перезагрузите systemd:
   ```bash
   sudo systemctl daemon-reload
   ```
