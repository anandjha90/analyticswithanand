import logging

# Configure logging
logging.basicConfig(
    level=logging.ERROR,  # Log level
    format="%(asctime)s - %(levelname)s - %(message)s"
)

try:
    # Intentionally cause a ZeroDivisionError
    result = 1 / 0
except ZeroDivisionError as e:
    logging.error("An error occurred: Division by zero.", exc_info=True)
