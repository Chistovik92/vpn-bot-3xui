#!/usr/bin/env python3
"""
Главный файл запуска VPN бота
"""

import logging
import sys
import os

# Добавляем корневую директорию в путь
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from bot.main import main

if __name__ == "__main__":
    try:
        print("🚀 Запуск VPN Bot для 3x-ui...")
        main()
    except KeyboardInterrupt:
        print("\n⏹ Остановка бота...")
    except Exception as e:
        print(f"❌ Ошибка запуска: {e}")
        sys.exit(1)