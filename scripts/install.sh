#!/bin/bash

# Скрипт первоначальной настройки

set -e

echo "🔧 Настройка VPN Bot..."

# Создание необходимых директорий
mkdir -p logs
mkdir -p database/backups

# Установка прав на скрипты
chmod +x scripts/*.sh

# Создание конфига если не существует
if [ ! -f "config.yaml" ]; then
    cat > config.yaml << EOF
# Конфигурация VPN Bot
bot:
  name: "VPN Bot"
  admin_ids: []
  log_level: "INFO"

payments:
  yoomoney:
    enabled: true
  telegram_stars:
    enabled: false

vpn:
  default_duration: 30
  max_devices: 3
EOF
    echo "✅ Создан config.yaml"
fi

echo "✅ Настройка завершена"