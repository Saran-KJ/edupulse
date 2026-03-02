import os
from sqlalchemy import create_engine, text
from config import Settings

def normalize_roles():
    # Get the PostgreSQL URL from Settings (uses .env if present)
    db_url = Settings().database_url
    engine = create_engine(db_url)
    with engine.begin() as conn:
        # Update any role values that are not already lowercase
        conn.execute(
            text(
                """
                UPDATE users
                SET role = LOWER(role)
                WHERE role <> LOWER(role);
                """
            )
        )
        # Verify that all roles are now lowercase
        result = conn.execute(text("SELECT user_id, role FROM users WHERE role <> LOWER(role)"))
        remaining = result.fetchall()
        if remaining:
            print('Some roles still not normalized:', remaining)
        else:
            print('All role values normalized to lowercase.')

if __name__ == '__main__':
    normalize_roles()
