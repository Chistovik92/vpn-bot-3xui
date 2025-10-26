import requests
import json
import logging
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

class XUIAPI:
    def __init__(self, panel_url: str, username: str, password: str):
        self.panel_url = panel_url.rstrip('/')
        self.session = requests.Session()
        self.login(username, password)
    
    def login(self, username: str, password: str) -> bool:
        """Авторизация в панели 3x-ui"""
        try:
            login_data = {
                "username": username,
                "password": password
            }
            response = self.session.post(f"{self.panel_url}/login", data=login_data)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Ошибка авторизации в 3x-ui: {e}")
            return False
    
    def get_inbounds(self) -> Optional[Dict[str, Any]]:
        """Получение списка инбаундов"""
        try:
            response = self.session.get(f"{self.panel_url}/panel/api/inbounds")
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Ошибка получения инбаундов: {e}")
        return None
    
    def create_client(self, inbound_id: int, email: str, limit_ip: int = 1, enable: bool = True) -> bool:
        """Создание клиента в инбаунде"""
        try:
            client_data = {
                "id": inbound_id,
                "settings": json.dumps({
                    "clients": [{
                        "id": email,
                        "email": email,
                        "limitIp": limit_ip,
                        "enable": enable
                    }]
                })
            }
            response = self.session.post(
                f"{self.panel_url}/panel/api/inbounds/addClient",
                data=client_data
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Ошибка создания клиента: {e}")
            return False
    
    def get_client_config(self, inbound_id: int, email: str) -> Optional[str]:
        """Получение конфигурации клиента"""
        try:
            data = {
                "id": inbound_id,
                "email": email
            }
            response = self.session.post(
                f"{self.panel_url}/panel/api/inbounds/getClientTraffics/{email}",
                data=data
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Ошибка получения конфига клиента: {e}")
        return None