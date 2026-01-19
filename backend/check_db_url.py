from config import get_settings

def print_db_url():
    settings = get_settings()
    print(f"Database URL: {settings.database_url}")

if __name__ == "__main__":
    print_db_url()
