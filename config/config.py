import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Telegram
    BOT_TOKEN = os.getenv('BOT_TOKEN')
    
    # YooMoney
    YOOMONEY_TOKEN = os.getenv('YOOMONEY_TOKEN')
    YOOMONEY_RECEIVER = os.getenv('YOOMONEY_RECEIVER')
    
    # 3x-ui
    XUI_PANEL_URL = os.getenv('XUI_PANEL_URL')
    XUI_USERNAME = os.getenv('XUI_USERNAME')
    XUI_PASSWORD = os.getenv('XUI_PASSWORD')
    
    # Database
    DATABASE_PATH = os.getenv('DATABASE_PATH', './database/vpn_bot.db')
    
    # Admin
    ADMIN_IDS = [int(x.strip()) for x in os.getenv('ADMIN_IDS', '').split(',') if x.strip()]
    
    # Prices
    PRICES = {
        '1_month': int(os.getenv('PRICE_1_MONTH', 100)),
        '3_months': int(os.getenv('PRICE_3_MONTHS', 250)),
        '6_months': int(os.getenv('PRICE_6_MONTHS', 450)),
        '12_months': int(os.getenv('PRICE_12_MONTHS', 800))
    }