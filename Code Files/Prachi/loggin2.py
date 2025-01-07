import logging
from logging.handlers import RotatingFileHandler

# Configure rotating logs
handler = RotatingFileHandler("app.log", maxBytes=2000, backupCount=5)
logging.basicConfig(level=logging.INFO, handlers=[handler])

for i in range(100):
    logging.info(f"Log message {i}")
