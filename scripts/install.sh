#!/bin/bash

set -e

echo "🔄 Установка VPN Bot для 3x-ui..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Проверка прав root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_status "Скрипт запущен с правами root"
    else
        print_error "Этот скрипт требует прав root для установки обновлений системы"
        echo "Запустите скрипт с помощью: sudo $0"
        exit 1
    fi
}

# Определение дистрибутива
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$ID
        OS_VERSION=$VERSION_ID
        print_status "Обнаружена ОС: $NAME $VERSION"
    elif [ -f /etc/redhat-release ]; then
        OS_NAME="rhel"
        OS_VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9]\).*/\1/')
        print_status "Обнаружена ОС: Red Hat Enterprise Linux $OS_VERSION"
    else
        print_error "Не удалось определить дистрибутив Linux"
        exit 1
    fi
}

# Обновление системы
update_system() {
    print_step "Обновление системы до последней версии..."
    
    case $OS_NAME in
        ubuntu|debian)
            print_status "Обновление пакетов для Ubuntu/Debian..."
            apt update && apt upgrade -y
            apt autoremove -y
            apt clean
            ;;
        centos|rhel|fedora)
            print_status "Обновление пакетов для CentOS/RHEL/Fedora..."
            if command -v dnf &>/dev/null; then
                dnf update -y
                dnf autoremove -y
                dnf clean all
            else
                yum update -y
                yum autoremove -y
                yum clean all
            fi
            ;;
        *)
            print_warning "Автоматическое обновление не поддерживается для $OS_NAME"
            print_warning "Пожалуйста, обновите систему вручную"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_status "Система успешно обновлена"
    else
        print_error "Ошибка при обновлении системы"
        return 1
    fi
}

# Установка критических обновлений безопасности
install_security_updates() {
    print_step "Установка критических обновлений безопасности..."
    
    case $OS_NAME in
        ubuntu|debian)
            apt list --upgradable 2>/dev/null | grep -i security | cut -d'/' -f1 | xargs apt install -y
            ;;
        centos|rhel|fedora)
            if command -v dnf &>/dev/null; then
                dnf update --security -y
            else
                yum update --security -y
            fi
            ;;
    esac
    
    print_status "Обновления безопасности установлены"
}

# Обновление системных компонентов
update_system_components() {
    print_step "Обновление системных компонентов..."
    
    case $OS_NAME in
        ubuntu|debian)
            # Обновление ядра и системных утилит
            apt install -y linux-generic htop net-tools curl wget git build-essential
            ;;
        centos|rhel|fedora)
            if command -v dnf &>/dev/null; then
                dnf install -y kernel kernel-devel htop net-tools curl wget git gcc-c++
            else
                yum install -y kernel kernel-devel htop net-tools curl wget git gcc-c++
            fi
            ;;
    esac
}

# Проверка Python
check_python() {
    print_step "Проверка установки Python..."
    
    if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        print_status "Найден Python3"
    elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
        print_status "Найден Python"
    else
        print_warning "Python не установлен. Установка Python..."
        
        case $OS_NAME in
            ubuntu|debian)
                apt install -y python3 python3-pip python3-venv
                PYTHON_CMD="python3"
                ;;
            centos|rhel|fedora)
                if command -v dnf &>/dev/null; then
                    dnf install -y python3 python3-pip
                else
                    yum install -y python3 python3-pip
                fi
                PYTHON_CMD="python3"
                ;;
            *)
                print_error "Не удалось установить Python автоматически"
                echo "Установите Python 3.8+ вручную:"
                echo "Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip"
                echo "CentOS/RHEL: sudo yum install python3 python3-pip"
                exit 1
                ;;
        esac
    fi
    
    # Проверяем версию Python
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
    print_status "Версия Python: $PYTHON_VERSION"
    
    # Проверяем, что версия >= 3.8
    MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d. -f1)
    MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ $MAJOR_VERSION -lt 3 ] || ([ $MAJOR_VERSION -eq 3 ] && [ $MINOR_VERSION -lt 8 ]); then
        print_warning "Требуется Python 3.8 или выше. Текущая версия: $PYTHON_VERSION"
        print_status "Установка более новой версии Python..."
        
        case $OS_NAME in
            ubuntu|debian)
                if [[ "$OS_NAME" == "ubuntu" && "$OS_VERSION" == "18.04" ]]; then
                    apt install -y software-properties-common
                    add-apt-repository -y ppa:deadsnakes/ppa
                    apt update
                    apt install -y python3.8 python3.8-pip python3.8-venv
                    PYTHON_CMD="python3.8"
                else
                    apt install -y python3-pip python3-venv
                fi
                ;;
            centos|rhel|fedora)
                if command -v dnf &>/dev/null; then
                    dnf install -y python3-pip
                else
                    yum install -y python3-pip
                fi
                ;;
        esac
    fi
}

# Проверка и установка pip
check_pip() {
    print_step "Проверка установки pip..."
    
    if command -v pip3 &>/dev/null; then
        PIP_CMD="pip3"
        print_status "Найден pip3"
    elif command -v pip &>/dev/null; then
        PIP_CMD="pip"
        print_status "Найден pip"
    else
        print_warning "Pip не установлен. Установка pip..."
        
        case $OS_NAME in
            ubuntu|debian)
                apt install -y python3-pip
                PIP_CMD="pip3"
                ;;
            centos|rhel|fedora)
                if command -v dnf &>/dev/null; then
                    dnf install -y python3-pip
                else
                    yum install -y python3-pip
                fi
                PIP_CMD="pip3"
                ;;
        esac
    fi
    
    # Обновление pip до последней версии
    print_status "Обновление pip до последней версии..."
    $PIP_CMD install --upgrade pip
}

# Установка зависимостей
install_dependencies() {
    print_step "Установка зависимостей Python..."
    
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
    print_step "Инициализация базы данных..."
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
        print_step "Создание файла конфигурации..."
        cp .env.example .env
        print_warning "Отредактируйте файл .env перед запуском бота: nano .env"
    else
        print_status "Файл .env уже существует"
    fi
}

# Оптимизация системы (опционально)
optimize_system() {
    print_step "Оптимизация системных настроек..."
    
    # Увеличиваем лимиты для файлов (полезно для бота)
    if ! grep -q "bot_optimizations" /etc/security/limits.conf; then
        echo "# bot_optimizations" >> /etc/security/limits.conf
        echo "* soft nofile 65536" >> /etc/security/limits.conf
        echo "* hard nofile 65536" >> /etc/security/limits.conf
        print_status "Лимиты файлов увеличены"
    fi
    
    # Настройка swappiness для лучшей производительности
    if [ -f /proc/sys/vm/swappiness ]; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
        print_status "Настройка swappiness оптимизирована"
    fi
}

# Основная установка
main() {
    echo "========================================"
    echo "   Установка VPN Bot для 3x-ui"
    echo "========================================"
    
    # Проверка прав root
    check_root
    
    # Определение ОС
    detect_os
    
    # Обновление системы
    update_system
    
    # Установка обновлений безопасности
    install_security_updates
    
    # Обновление системных компонентов
    update_system_components
    
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
    
    # Оптимизация системы
    optimize_system
    
    echo ""
    print_status "Установка завершена! 🎉"
    echo ""
    print_warning "Следующие шаги:"
    echo "1. Отредактируйте файл .env: nano .env"
    echo "2. Запустите бота: $PYTHON_CMD start_bot.py"
    echo "3. Или используйте Docker: docker-compose up -d"
    echo ""
    print_status "Документация: docs/SETUP.md"
    echo ""
    print_status "Рекомендуется перезагрузить систему: sudo reboot"
}

# Запуск установки
main