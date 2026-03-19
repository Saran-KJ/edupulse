from database import SessionLocal
import models

db = SessionLocal()
user = db.query(models.User).filter(models.User.email == "zoro@gmail.com").first()
if user:
    print(f"User: {user.name}, Role: {user.role}")
else:
    print("User not found")

coords = db.query(models.ProjectCoordinator).all()
print(f"Coordinators: {len(coords)}")
for c in coords:
    print(f"ID: {c.id}, FacultyID: {c.faculty_id}, Dept: {c.dept}, Year: {c.year}")
db.close()
