#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Функции для вывода сообщений
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

# Проверка виртуального окружения
check_venv() {
    if [ -d "venv" ]; then
        print_status "Активация виртуального окружения..."
        source venv/bin/activate
        return 0
    else
        print_warning "Виртуальное окружение не найдено"
        return 1
    fi
}

# Проверка зависимостей
check_dependencies() {
    print_step "Проверка установленных зависимостей..."
    
    # Проверяем основные пакеты
    local missing_packages=()
    
    if ! python -c "import telegram" &>/dev/null; then
        missing_packages+=("python-telegram-bot")
    fi
    
    if ! python -c "import requests" &>/dev/null; then
        missing_packages+=("requests")
    fi
    
    if ! python -c "import sqlalchemy" &>/dev/null; then
        missing_packages+=("sqlalchemy")
    fi
    
    if ! python -c "import dotenv" &>/dev/null; then
        missing_packages+=("python-dotenv")
    fi
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        print_warning "Не найдены пакеты: ${missing_packages[*]}"
        print_status "Установка недостающих зависимостей..."
        pip install "${missing_packages[@]}"
        
        if [ $? -eq 0 ]; then
            print_status "Зависимости успешно установлены"
        else
            print_error "Ошибка установки зависимостей"
            return 1
        fi
    else
        print_status "Все зависимости установлены"
    fi
}

# Проверка конфигурации
check_config() {
    print_step "Проверка конфигурации..."
    
    if [ ! -f ".env" ]; then
        print_error "Файл .env не найден!"
        echo "Создайте файл .env на основе .env.example:"
        echo "  cp .env.example .env"
        echo "Затем отредактируйте .env и добавьте настройки бота"
        return 1
    fi
    
    # Проверяем обязательные переменные
    local missing_vars=()
    
    if ! grep -q "BOT_TOKEN" .env || grep -q "BOT_TOKEN=your_bot_token_here" .env; then
        missing_vars+=("BOT_TOKEN")
    fi
    
    if ! grep -q "XUI_URL" .env || grep -q "XUI_URL=http://localhost:54321" .env; then
        missing_vars+=("XUI_URL")
    fi
    
    if ! grep -q "XUI_USERNAME" .env || grep -q "XUI_USERNAME=admin" .env; then
        missing_vars+=("XUI_USERNAME")
    fi
    
    if ! grep -q "XUI_PASSWORD" .env || grep -q "XUI_PASSWORD=admin" .env; then
        missing_vars+=("XUI_PASSWORD")
    fi
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_warning "Не настроены обязательные переменные: ${missing_vars[*]}"
        echo "Отредактируйте файл .env: nano .env"
        return 1
    fi
    
    print_status "Конфигурация проверена успешно"
    return 0
}

# Проверка базы данных
check_database() {
    print_step "Проверка базы данных..."
    
    if [ ! -f "vpn_bot.db" ] && [ ! -f "database/vpn_bot.db" ]; then
        print_warning "База данных не найдена, выполняется инициализация..."
        
        if [ -f "database/init_db.py" ]; then
            python database/init_db.py
            if [ $? -eq 0 ]; then
                print_status "База данных инициализирована"
            else
                print_error "Ошибка инициализации базы данных"
                return 1
            fi
        else
            print_error "Скрипт инициализации БД не найден"
            return 1
        fi
    else
        print_status "База данных найдена"
    fi
}

# Поиск основного файла бота
find_bot_file() {
    local bot_files=("bot.py" "main.py" "start_bot.py" "app.py" "core.py")
    
    for file in "${bot_files[@]}"; do
        if [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done
    
    return 1
}

# Остановка бота
stop_bot() {
    print_status "Остановка бота..."
    
    # Ищем процесс бота
    local bot_pids=$(ps aux | grep -v grep | grep -E "(bot\.py|main\.py|start_bot\.py|app\.py|core\.py)" | awk '{print $2}')
    
    if [ -n "$bot_pids" ]; then
        echo "$bot_pids" | xargs kill -TERM
        sleep 3
        
        # Принудительное завершение если нужно
        local still_running=$(ps aux | grep -v grep | grep -E "(bot\.py|main\.py|start_bot\.py|app\.py|core\.py)" | awk '{print $2}')
        if [ -n "$still_running" ]; then
            echo "$still_running" | xargs kill -KILL
        fi
        
        print_status "Бот остановлен"
    else
        print_status "Бот не запущен"
    fi
}

# Запуск бота в фоновом режиме
start_background() {
    local bot_file=$1
    local log_file="bot.log"
    
    print_status "Запуск бота в фоновом режиме..."
    print_status "Логи будут записываться в: $log_file"
    
    nohup python "$bot_file" > "$log_file" 2>&1 &
    local bot_pid=$!
    
    echo $bot_pid > "bot.pid"
    print_status "Бот запущен с PID: $bot_pid"
    
    # Ждем немного и проверяем что бот запустился
    sleep 2
    if ps -p $bot_pid > /dev/null; then
        print_status "✅ Бот успешно запущен!"
        print_status "🔍 Просмотр логов: tail -f $log_file"
        print_status "⏹️  Остановка бота: ./start.sh stop"
    else
        print_error "❌ Не удалось запустить бот"
        print_status "📋 Проверьте логи: tail -n 50 $log_file"
    fi
}

# Запуск бота в режиме разработки
start_development() {
    local bot_file=$1
    
    print_status "Запуск бота в режиме разработки..."
    print_status "Для остановки нажмите Ctrl+C"
    echo ""
    
    python "$bot_file"
}

# Просмотр логов
show_logs() {
    local log_file="bot.log"
    
    if [ ! -f "$log_file" ]; then
        print_error "Файл логов не найден: $log_file"
        return 1
    fi
    
    print_status "Последние 50 строк логов:"
    tail -n 50 "$log_file"
    
    echo ""
    print_status "Для просмотра в реальном времени: tail -f $log_file"
}

# Проверка статуса бота
check_status() {
    local pid_file="bot.pid"
    
    if [ -f "$pid_file" ]; then
        local bot_pid=$(cat "$pid_file")
        if ps -p "$bot_pid" > /dev/null; then
            print_status "✅ Бот запущен (PID: $bot_pid)"
            
            # Показываем время работы
            local uptime=$(ps -o etime= -p "$bot_pid" | xargs)
            print_status "⏱️  Время работы: $uptime"
            
            # Показываем использование памяти
            local memory=$(ps -o rss= -p "$bot_pid" | xargs)
            if [ -n "$memory" ]; then
                local memory_mb=$((memory / 1024))
                print_status "💾 Использование памяти: ${memory_mb} MB"
            fi
            
            return 0
        else
            print_warning "❌ Бот не запущен (PID файл существует, но процесс не найден)"
            rm -f "$pid_file"
            return 1
        fi
    else
        print_warning "❌ Бот не запущен (PID файл не найден)"
        return 1
    fi
}

# Основная функция
main() {
    local command=${1:-"start"}
    
    case $command in
        "start" | "run")
            print_step "Запуск VPN Bot для 3x-ui..."
            
            # Проверяем виртуальное окружение
            if ! check_venv; then
                print_error "Не удалось активировать виртуальное окружение"
                exit 1
            fi
            
            # Проверяем конфигурацию
            if ! check_config; then
                print_error "Проверьте конфигурацию перед запуском"
                exit 1
            fi
            
            # Проверяем базу данных
            if ! check_database; then
                print_error "Проблемы с базой данных"
                exit 1
            fi
            
            # Проверяем зависимости
            if ! check_dependencies; then
                print_error "Проблемы с зависимостями"
                exit 1
            fi
            
            # Ищем файл бота
            local bot_file=$(find_bot_file)
            if [ -z "$bot_file" ]; then
                print_error "Не найден файл бота!"
                echo "Доступные Python файлы:"
                ls *.py 2>/dev/null || echo "   (нет файлов .py)"
                exit 1
            fi
            
            print_status "Найден файл бота: $bot_file"
            
            # Останавливаем предыдущую версию если запущена
            stop_bot
            
            # Запускаем в фоновом режиме
            start_background "$bot_file"
            ;;
            
        "stop" | "kill")
            stop_bot
            ;;
            
        "restart")
            print_step "Перезапуск бота..."
            $0 stop
            sleep 2
            $0 start
            ;;
            
        "status")
            check_status
            ;;
            
        "logs")
            show_logs
            ;;
            
        "dev" | "development")
            print_step "Запуск в режиме разработки..."
            
            if ! check_venv; then
                print_error "Не удалось активировать виртуальное окружение"
                exit 1
            fi
            
            if ! check_config; then
                print_error "Проверьте конфигурацию перед запуском"
                exit 1
            fi
            
            local bot_file=$(find_bot_file)
            if [ -z "$bot_file" ]; then
                print_error "Не найден файл бота!"
                exit 1
            fi
            
            stop_bot
            start_development "$bot_file"
            ;;
            
        "update")
            print_step "Обновление бота..."
            
            # Останавливаем бота
            stop_bot
            
            # Обновляем зависимости
            if check_venv; then
                print_status "Обновление зависимостей..."
                if [ -f "requirements.txt" ]; then
                    pip install -r requirements.txt --upgrade
                fi
            fi
            
            print_status "Обновление завершено, запустите бота снова: ./start.sh start"
            ;;
            
        "clean")
            print_step "Очистка временных файлов..."
            
            stop_bot
            
            # Удаляем логи и PID файлы
            rm -f bot.log bot.pid
            
            print_status "Временные файлы очищены"
            ;;
            
        "help" | "--help" | "-h")
            echo "Использование: ./start.sh [команда]"
            echo ""
            echo "Команды:"
            echo "  start, run    - Запуск бота в фоновом режиме"
            echo "  stop, kill    - Остановка бота"
            echo "  restart       - Перезапуск бота"
            echo "  status        - Показать статус бота"
            echo "  logs          - Показать логи бота"
            echo "  dev, develop  - Запуск в режиме разработки (в консоли)"
            echo "  update        - Обновить зависимости и перезапустить"
            echo "  clean         - Очистить логи и временные файлы"
            echo "  help          - Показать эту справку"
            echo ""
            ;;
            
        *)
            print_error "Неизвестная команда: $command"
            echo "Используйте: ./start.sh help для просмотра доступных команд"
            exit 1
            ;;
    esac
}

# Обработка сигналов
cleanup() {
    print_status "Завершение работы..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Запуск основной функции
main "$@"