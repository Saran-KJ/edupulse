from database import SessionLocal
import models

db = SessionLocal()
user = db.query(models.User).filter(models.User.email == "zoro@gmail.com").first()
if user:
    print(f"User: {user.name}, ID: {user.user_id}, Role: {user.role}")
else:
    print("User not found")
db.close()
