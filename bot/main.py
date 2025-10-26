import logging
import asyncio
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, MessageHandler, filters
from config.config import Config
from database.init_db import init_db
from bot.handlers.start import start, handle_callback
from bot.handlers.payments import deposit, check_payment
from bot.handlers.vpn import buy_vpn, my_subscriptions

# Настройка логирования
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

class VPNBot:
    def __init__(self, config: Config):
        self.config = config
        self.application = Application.builder().token(config.BOT_TOKEN).build()
        self.setup_handlers()
    
    def setup_handlers(self):
        # Команды
        self.application.add_handler(CommandHandler("start", start))
        self.application.add_handler(CommandHandler("buy", buy_vpn))
        self.application.add_handler(CommandHandler("balance", deposit))
        self.application.add_handler(CommandHandler("profile", my_subscriptions))
        
        # Callback queries
        self.application.add_handler(CallbackQueryHandler(handle_callback))
        
        # Сообщения
        self.application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, self.handle_message))
    
    async def handle_message(self, update, context):
        await update.message.reply_text("Используйте команды из меню для взаимодействия с ботом.")
    
    def run(self):
        # Инициализация БД
        init_db()
        
        # Запуск бота
        self.application.run_polling()

def main():
    config = Config()
    bot = VPNBot(config)
    bot.run()

if __name__ == "__main__":
    main()