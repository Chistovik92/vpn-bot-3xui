#!/bin/bash

set -e

echo "🔄 Обновление VPN Bot..."

# Определяем команды Python
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Python не найден"
    exit 1
fi

# Обновляем код из Git
echo "📥 Получение обновлений из Git..."
git pull origin main

# Обновляем зависимости
echo "📦 Обновление зависимостей..."
if command -v pip3 &>/dev/null; then
    pip3 install -r requirements.txt --upgrade
elif command -v pip &>/dev/null; then
    pip install -r requirements.txt --upgrade
fi

# Обновляем базу данных если нужно
echo "🗃️ Проверка обновлений базы данных..."
$PYTHON_CMD database/init_db.py

echo "✅ Обновление завершено!"
echo "🔄 Перезапустите бота: $PYTHON_CMD start_bot.py"