import logging
import random
import time

# Configure logging
LOG_FILE = "website_activity.log"
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),        # Log to a file
        logging.StreamHandler()              # Log critical messages to the console
    ]
)

# Simulated website pages
PAGES = ["/home", "/about", "/contact", "/products", "/cart", "/checkout"]

def visit_page(page):
    """Simulates a user visiting a page."""
    logging.info(f"User visited {page}")
    if random.choice([True, False]):  # Simulate random warnings
        logging.warning(f"Page {page} is taking longer to load.")

def perform_action(page):
    """Simulates a user action on a page."""
    actions = ["clicked a button", "filled a form", "added item to cart", "proceeded to checkout"]
    action = random.choice(actions)
    logging.info(f"User {action} on {page}")
    if random.choice([True, False]):  # Simulate random errors
        logging.error(f"Error encountered while performing action on {page}!")

def simulate_website_activity():
    """Simulates website activity."""
    for _ in range(20):  # Simulate 20 random activities
        page = random.choice(PAGES)
        visit_page(page)
        time.sleep(0.5)  # Simulate a delay
        perform_action(page)

def main():
    logging.debug("Starting the website activity simulation.")
    try:
        simulate_website_activity()
    except Exception as e:
        logging.critical(f"Critical error occurred: {e}", exc_info=True)
    logging.debug("Finished the website activity simulation.")

if __name__ == "__main__":
    main()
