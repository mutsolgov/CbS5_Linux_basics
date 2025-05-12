#!/usr/bin/env bash

# get_all_info.sh
#  Скрипт для сбора информации о Linux-системе:
# - список установленных пакетов
# - список запущенных процессов
# - список открытых портов
# - установка пакетов cowsay и sl
# - версия ядра и OC
# Результат сохраняется в файл `info` и архивируется в `OS_RESULT.tar`.

# 1. Проверка прав: запускается только от root
if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт нужно запускать от root" >&2
    exit 1
fi

# 2. Определяем пакетный менеджер (apt, yum, dnf, pacman)
if command -v apt >/dev/null 2>&1; then
    PM="apt"
    LIST_PACKAGES="dpkg-query -l"
    INSTALL="apt install -y"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
    LIST_PACKAGES="yum list installed"
    INSTALL="yum install -y"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
    LIST_PACKAGES="dnf list installed"
    INSTALL="dnf install -y"
elif command -v pacman >/dev/null 2>&1; then
    PM="pacman"
    LIST_PACKAGES="pacman -Q"
    INSTALL="pacman -Sy --noconfirm"
else
    echo "Неизвестный или неподдерживаемый пакетный менеджер" >&2
    exit 2
fi

# 3. Создаем или очищаем файл info
OUTPUT_FILE="info"
> "$OUTPUT_FILE"

# 4. Собираем список установленных пакетов 
echo "=== Установленные пакеты ($PM) ===" >> "$OUTPUT_FILE"
$LIST_PACKAGES >> "$OUTPUT_FILE" 2>&1

# 5. Собираем список запущенных процессов
echo -e "\n=== Запущенные процессы (ps aux) ===" >> "$OUTPUT_FILE"
ps aux >> "$OUTPUT_FILE" 2>&1

# 6. Собираем список открытых портов
echo -e "\n=== Открытые порты (ss -tuln или netstat) ===" >> "$OUTPUT_FILE"
if command -v ss >/dev/null 2>&1; then
    ss -tuln >> "$OUTPUT_FILE" 2>&1
else 
    netstat -tuln >> "$OUTPUT_FILE" 2>&1
fi

# 7. Устанавливаем мем-пакеты cowsay и sl
echo -e "\n=== Установка cowsay и sl ===" >> "$OUTPUT_FILE"
$INSTALL cowsay sl >> "$OUTPUT_FILE" 2>&1

# 8. Сохраняем версию ядра
echo -e "\n=== Версия ядра (uname -r) ===" >> "$OUTPUT_FILE"
uname -r >> "$OUTPUT_FILE" 2>&1

# 9. Сохраняем версию OC
echo -e "\n=== Информация об ОС (/etc/os-release) ===" >> "$OUTPUT_FILE"
if [[ -f /etc/os-release ]]; then
    cat /etc/os-release >> "$OUTPUT_FILE" 2>&1
else
    echo " Файл /etc/os-release не найденб пробую lsb_release" >> "$OUTPUT_FILE"
    lsb_release -a >> "$OUTPUT_FILE" 2>&1
fi

# 10. Архивация результата
tar -cvf OS_RESULT.tar "$OUTPUT_FILE"

echo "Сбор информации завершен. Результат - OS_RESULT.tar"

