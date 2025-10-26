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
            apt install -y linux-generic htop net-tools curl wget git build-essential python3-venv python3-full
            ;;
        centos|rhel|fedora)
            if command -v dnf &>/dev/null; then
                dnf install -y kernel kernel-devel htop net-tools curl wget git gcc-c++ python3-venv
            else
                yum install -y kernel kernel-devel htop net-tools curl wget git gcc-c++ python3-venv
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
                apt install -y python3 python3-pip python3-venv python3-full
                PYTHON_CMD="python3"
                ;;
            centos|rhel|fedora)
                if command -v dnf &>/dev/null; then
                    dnf install -y python3 python3-pip python3-venv
                else
                    yum install -y python3 python3-pip python3-venv
                fi
                PYTHON_CMD="python3"
                ;;
            *)
                print_error "Не удалось установить Python автоматически"
                echo "Установите Python 3.8+ вручную:"
                echo "Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip python3-venv"
                echo "CentOS/RHEL: sudo yum install python3 python3-pip python3-venv"
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
                    apt install -y python3-pip python3-venv python3-full
                fi
                ;;
            centos|rhel|fedora)
                if command -v dnf &>/dev/null; then
                    dnf install -y python3-pip python3-venv
                else
                    yum install -y python3-pip python3-venv
                fi
                ;;
        esac
    fi
}

# Создание виртуального окружения
create_venv() {
    print_step "Создание виртуального окружения Python..."
    
    if [ -d "venv" ]; then
        print_status "Виртуальное окружение уже существует"
    else
        $PYTHON_CMD -m venv venv
        if [ $? -eq 0 ]; then
            print_status "Виртуальное окружение создано"
        else
            print_error "Ошибка создания виртуального окружения"
            print_status "Установка дополнительных пакетов..."
            case $OS_NAME in
                ubuntu|debian)
                    apt install -y python3-venv python3-full
                    ;;
                centos|rhel|fedora)
                    if command -v dnf &>/dev/null; then
                        dnf install -y python3-venv
                    else
                        yum install -y python3-venv
                    fi
                    ;;
            esac
            # Повторная попытка
            $PYTHON_CMD -m venv venv
            if [ $? -ne 0 ]; then
                print_error "Не удалось создать виртуальное окружение"
                exit 1
            fi
        fi
    fi
    
    # Активация виртуального окружения
    source venv/bin/activate
    
    # Обновление pip в виртуальном окружении
    print_status "Обновление pip в виртуальном окружении..."
    pip install --upgrade pip
}

# Проверка и установка pip в виртуальном окружении
check_pip() {
    print_step "Проверка установки pip в виртуальном окружении..."
    
    if command -v pip &>/dev/null; then
        PIP_CMD="pip"
        print_status "Найден pip в виртуальном окружении"
    else
        print_error "Pip не найден в виртуальном окружении"
        exit 1
    fi
}

# Установка зависимостей
install_dependencies() {
    print_step "Установка зависимостей Python в виртуальном окружении..."
    
    # Проверяем существование requirements.txt
    if [ ! -f "requirements.txt" ]; then
        print_error "Файл requirements.txt не найден"
        print_status "Создание базового requirements.txt..."
        cat > requirements.txt << EOF
python-telegram-bot>=20.0
requests>=2.28.0
python-dotenv>=0.19.0
sqlalchemy>=1.4.0
apscheduler>=3.10.0
cryptography>=3.4.0
EOF
        print_status "Создан базовый requirements.txt"
    fi
    
    pip install -r requirements.txt
    
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
    
    # Создаем скрипт инициализации БД, если его нет
    if [ ! -f "database/init_db.py" ]; then
        print_warning "Скрипт инициализации БД не найден, создаем базовый..."
        mkdir -p database
        cat > database/init_db.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
from sqlalchemy import create_engine, text

def init_database():
    # Базовая инициализация БД
    db_path = "vpn_bot.db"
    engine = create_engine(f"sqlite:///{db_path}")
    
    with engine.connect() as conn:
        # Создаем таблицу пользователей
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                telegram_id INTEGER UNIQUE NOT NULL,
                username TEXT,
                full_name TEXT,
                balance REAL DEFAULT 0.0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN DEFAULT TRUE
            )
        """))
        
        # Создаем таблицу серверов
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS servers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                url TEXT NOT NULL,
                username TEXT NOT NULL,
                password TEXT NOT NULL,
                is_active BOOLEAN DEFAULT TRUE
            )
        """))
        
        conn.commit()
    
    print("База данных успешно инициализирована")

if __name__ == "__main__":
    init_database()
EOF
        print_status "Создан базовый скрипт инициализации БД"
    fi
    
    python database/init_db.py
    
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
        if [ -f ".env.example" ]; then
            cp .env.example .env
        else
            print_warning "Файл .env.example не найден, создаем базовый .env..."
            cat > .env << 'EOF'
# Настройки Telegram Bot
BOT_TOKEN=your_bot_token_here
ADMIN_IDS=123456789,987654321

# Настройки 3x-ui панели
XUI_URL=http://localhost:54321
XUI_USERNAME=admin
XUI_PASSWORD=admin

# Настройки базы данных
DATABASE_URL=sqlite:///vpn_bot.db

# Настройки оплаты
YOOMONEY_TOKEN=your_yoomoney_token
CRYPTOBOT_TOKEN=your_cryptobot_token

# Другие настройки
DEBUG=false
LOG_LEVEL=INFO
EOF
        fi
        print_warning "Отредактируйте файл .env перед запуском бота: nano .env"
    else
        print_status "Файл .env уже существует"
    fi
}

# Создание скрипта запуска
create_start_script() {
    print_step "Создание скрипта запуска..."
    
    cat > start.sh << 'EOF'
#!/bin/bash

# Активация виртуального окружения
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Запуск бота
if [ -f "bot.py" ]; then
    python bot.py
elif [ -f "main.py" ]; then
    python main.py
elif [ -f "start_bot.py" ]; then
    python start_bot.py
else
    echo "Файл бота не найден! Доступные файлы:"
    ls *.py
fi
EOF
    
    chmod +x start.sh
    
    cat > start_bot.py << 'EOF'
#!/usr/bin/env python3
import os
import logging
from dotenv import load_dotenv

# Загрузка переменных окружения
load_dotenv()

def main():
    # Базовая настройка логирования
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    print("VPN Bot для 3x-ui запускается...")
    print("Пожалуйста, настройте бота в соответствии с документацией")
    
    # Проверяем обязательные переменные
    required_vars = ['BOT_TOKEN', 'XUI_URL', 'XUI_USERNAME', 'XUI_PASSWORD']
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"Ошибка: Отсутствуют обязательные переменные в .env: {', '.join(missing_vars)}")
        return
    
    print("Все обязательные настройки присутствуют")
    print("Для настройки бота отредактируйте файл .env и добавьте логику бота")

if __name__ == "__main__":
    main()
EOF
    
    print_status "Созданы скрипты запуска: start.sh и start_bot.py"
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
    if [ -f /proc/sys/vm/swappiness ] && ! grep -q "vm.swappiness" /etc/sysctl.conf; then
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
    
    # Создание виртуального окружения
    create_venv
    
    # Проверка pip
    check_pip
    
    # Установка зависимостей
    install_dependencies
    
    # Инициализация БД
    init_database
    
    # Настройка конфигурации
    setup_config
    
    # Создание скриптов запуска
    create_start_script
    
    # Оптимизация системы
    optimize_system
    
    echo ""
    print_status "Установка завершена! 🎉"
    echo ""
    print_warning "Следующие шаги:"
    echo "1. Отредактируйте файл .env: nano .env"
    echo "2. Добавьте ваш Telegram BOT_TOKEN и другие настройки"
    echo "3. Запустите бота: ./start.sh"
    echo "4. Или используйте Docker: docker-compose up -d"
    echo ""
    print_status "Для запуска бота используйте: source venv/bin/activate && python start_bot.py"
    echo ""
    print_status "Документация: docs/SETUP.md"
    echo ""
    print_status "Рекомендуется перезагрузить систему: sudo reboot"
}

# Запуск установки
main