#!/bin/bash

set -e

echo "🔄 Установка VPN Bot для 3x-ui..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Функция для вывода сообщений
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка Python
check_python() {
    if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        print_status "Найден Python3"
    elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
        print_status "Найден Python"
    else
        print_error "Python не установлен. Установите Python 3.8+"
        echo "Установка Python:"
        echo "Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip"
        echo "CentOS/RHEL: sudo yum install python3 python3-pip"
        exit 1
    fi
    
    # Проверяем версию Python
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
    print_status "Версия Python: $PYTHON_VERSION"
    
    # Проверяем, что версия >= 3.8
    MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d. -f1)
    MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ $MAJOR_VERSION -lt 3 ] || ([ $MAJOR_VERSION -eq 3 ] && [ $MINOR_VERSION -lt 8 ]); then
        print_error "Требуется Python 3.8 или выше. Текущая версия: $PYTHON_VERSION"
        exit 1
    fi
}

# Проверка и установка pip
check_pip() {
    if command -v pip3 &>/dev/null; then
        PIP_CMD="pip3"
        print_status "Найден pip3"
    elif command -v pip &>/dev/null; then
        PIP_CMD="pip"
        print_status "Найден pip"
    else
        print_error "Pip не установлен. Установите pip для продолжения"
        echo "Установка pip:"
        echo "Ubuntu/Debian: sudo apt install python3-pip"
        echo "CentOS/RHEL: sudo yum install python3-pip"
        exit 1
    fi
}

# Установка зависимостей
install_dependencies() {
    print_status "Установка зависимостей Python..."
    
    $PIP_CMD install -r requirements.txt
    
    if [ $? -eq 0 ]; then
        print_status "Зависимости успешно установлены"
    else
        print_error "Ошибка установки зависимостей"
        exit 1
    fi
}

# Инициализация базы данных
init_database() {
    print_status "Инициализация базы данных..."
    $PYTHON_CMD database/init_db.py
    
    if [ $? -eq 0 ]; then
        print_status "База данных инициализирована"
    else
        print_error "Ошибка инициализации базы данных"
        exit 1
    fi
}

# Создание конфигурации
setup_config() {
    if [ ! -f ".env" ]; then
        print_status "Создание файла конфигурации..."
        cp .env.example .env
        print_warning "Отредактируйте файл .env перед запуском бота: nano .env"
    else
        print_status "Файл .env уже существует"
    fi
}

# Основная установка
main() {
    echo "========================================"
    echo "   Установка VPN Bot для 3x-ui"
    echo "========================================"
    
    # Проверка Python
    check_python
    
    # Проверка pip
    check_pip
    
    # Установка зависимостей
    install_dependencies
    
    # Инициализация БД
    init_database
    
    # Настройка конфигурации
    setup_config
    
    echo ""
    print_status "Установка завершена! 🎉"
    echo ""
    print_warning "Следующие шаги:"
    echo "1. Отредактируйте файл .env: nano .env"
    echo "2. Запустите бота: $PYTHON_CMD start_bot.py"
    echo "3. Или используйте Docker: docker-compose up -d"
    echo ""
    print_status "Документация: docs/SETUP.md"
}

# Запуск установки
main