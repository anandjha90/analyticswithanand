import logging

# Configure logging
logging.basicConfig(
    filename="file_operations.log",  # Log file name
    level=logging.INFO,              # Log level
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def read_file(file_path):
    """Reads a file and logs operations."""
    try:
        logging.info(f"Attempting to read the file: {file_path}")
        
        with open(file_path, 'r') as file:
            line_count = 0
            empty_line_count = 0
            
            for line in file:
                line_count += 1
                if line.strip() == "":
                    empty_line_count += 1
                    logging.warning(f"Line {line_count}: Empty line found.")
                else:
                    logging.info(f"Line {line_count}: {line.strip()}")
        
        logging.info(f"File reading completed: {file_path}")
        logging.info(f"Total lines read: {line_count}, Empty lines: {empty_line_count}")
    
    except FileNotFoundError:
        logging.error(f"File not found: {file_path}")
    except Exception as e:
        logging.critical(f"An unexpected error occurred: {e}", exc_info=True)

if __name__ == "__main__":
    # Specify the file path to read
    file_to_read = "example.txt"
    
    # Call the function to read the file
    read_file(file_to_read)
