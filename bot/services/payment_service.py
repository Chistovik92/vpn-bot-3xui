import sqlite3
from yoomoney import Quickpay, Client
from config.config import Config
import logging

logger = logging.getLogger(__name__)

class PaymentService:
    def __init__(self, config: Config):
        self.config = config
        self.yoomoney_client = Client(config.YOOMONEY_TOKEN) if config.YOOMONEY_TOKEN else None
    
    def create_yoomoney_payment(self, user_id: int, amount: float) -> tuple[str, str]:
        """Создание платежа в YooMoney"""
        payment_id = f"{user_id}_{int(amount)}_{hash(str(user_id) + str(amount))}"
        
        quickpay = Quickpay(
            receiver=self.config.YOOMONEY_RECEIVER,
            quickpay_form="shop",
            targets="Пополнение баланса VPN бота",
            paymentType="SB",
            sum=amount,
            label=payment_id
        )
        
        # Сохраняем платеж в БД
        self.save_payment(payment_id, user_id, amount)
        
        return payment_id, quickpay.redirected_url
    
    def save_payment(self, payment_id: str, user_id: int, amount: float):
        """Сохранение платежа в БД"""
        conn = sqlite3.connect(self.config.DATABASE_PATH)
        c = conn.cursor()
        c.execute(
            "INSERT OR REPLACE INTO payments (payment_id, user_id, amount, status) VALUES (?, ?, ?, ?)",
            (payment_id, user_id, amount, 'pending')
        )
        conn.commit()
        conn.close()
    
    def check_payment(self, payment_id: str) -> bool:
        """Проверка статуса платежа"""
        if not self.yoomoney_client:
            return False
        
        try:
            history = self.yoomoney_client.operation_history(label=payment_id)
            for operation in history.operations:
                if operation.status == "success":
                    self.update_payment_status(payment_id, 'completed')
                    return True
        except Exception as e:
            logger.error(f"Ошибка проверки платежа: {e}")
        
        return False
    
    def update_payment_status(self, payment_id: str, status: str):
        """Обновление статуса платежа"""
        conn = sqlite3.connect(self.config.DATABASE_PATH)
        c = conn.cursor()
        c.execute(
            "UPDATE payments SET status = ? WHERE payment_id = ?",
            (status, payment_id)
        )
        
        if status == 'completed':
            # Пополняем баланс пользователя
            c.execute(
                "SELECT user_id, amount FROM payments WHERE payment_id = ?",
                (payment_id,)
            )
            result = c.fetchone()
            if result:
                user_id, amount = result
                c.execute(
                    "UPDATE users SET balance = balance + ? WHERE user_id = ?",
                    (amount, user_id)
                )
        
        conn.commit()
        conn.close()