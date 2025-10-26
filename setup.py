from setuptools import setup, find_packages

setup(
    name="vpn-bot-3xui",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "python-telegram-bot==20.7",
        "python-dotenv==1.0.0",
        "requests==2.31.0",
        "aiohttp==3.9.1",
        "yoomoney==0.18.0",
        "pyyaml==6.0.1"
    ],
    author="Your Name",
    description="VPN Bot for 3x-ui panel",
    python_requires=">=3.8",
)