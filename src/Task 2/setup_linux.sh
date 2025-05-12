#!/usr/bin/env bash

# setup_linux.sh
# Скрипт создания пользователей, групп и базовой настройки прав


# 1. Проверка прав: только root могут запускать
if [[ $EUID -ne 0 ]]; then
    echo "Запускайте скрипт от root" >&2
    exit 1
fi

# 2. Создаем группу default_users (если еще нет)
if ! getent group default_users >/dev/null; then
    groupadd default_users
    echo "Группа default_users создана"
else
    echo "Группа default_users уже существует"
fi

# 3. Создаем пользователя user и добавляем в default_users
if ! id user >/dev/null 2>&1; then
    useradd -m -G default_users user
    echo -e "\n Пользователь user создан, пароль нужно назначить вручную командой 'passwd user'"
else
    echo -e "\n Пользователь user уже существует"
fi

# 4. Создаем группу secret_users
if ! getent group secret_users >/dev/null; then
    groupadd secret_users
    echo -e "\n Группа secret_users создана"
else
    echo -e "\n Группа secret_users уже существует"
fi

# 5. Создаем секрктных пользователей в группе secret_users
for u in secret_agent secret_spy secret_boss; do
    if ! id $u >/dev/null 2>&1; then
        useradd -m -g secret_users $u
        echo -e "\n Пользователь $u создан, задайте пароль через 'passwd $u'"
    else
        echo -e "\n Пользователь $u уже существует"
    fi
done

# 6. Настраиваем права на домашние директории secret_users
#   - owner rwx, group rwx, other --- (chmod 770)
for u in secret_agent secret_spy secret_boss; do
    homedir="/home/$u"
    if [[ -d "$homedir" ]]; then
        chmod 770 "$homedir"
        echo -e "\n Права 770 установлены на $homedir"
    fi
done

# 7. Делегируем полный доступ к /var всем
chmod 777 /var
echo -e "\n Права 777 установлены на /var (чтение.запись.выполнение - у всех)"

# 8. Устанавливаем apache2 и проверяем сервис
if command -v apt >/dev/null 2>&1; then
    apt update && apt install -y apache2
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y httpd
elif command -v yum >/dev/null 2>&1; then
    yum install -y httpd
elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm apache
else
    echo -e "\n Неизвестный пакетный менеджер - apache не установлен" >&2
fi

# Проверяем статус сервиса
if systemctl is-active --quiet apache2; then
    echo -e "\n apache2 запушен"
elif systemctl is-active --quiet httpd; then
    echo -e "\n httpd запушен"
else
    echo -e "\n Apache-сервис не запущен или не установлен" >&2
fi

# 9. Разрешаем sudo без пароля для default_users
#   Добавляем файл /etc/sudoers.d/
SUDOERS_FILE="/etc/sudoers.d/default_users"
echo "%default_users ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
echo -e "\n Права sudo без пароля для группы default_users настроены"

echo "=== Настройка завершена ==="