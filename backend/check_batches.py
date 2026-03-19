from database import SessionLocal
import models

db = SessionLocal()
batches = db.query(models.ProjectBatch).filter(
    models.ProjectBatch.dept == "CSE",
    models.ProjectBatch.year == 4
).all()

print(f"Total batches for CSE Year 4: {len(batches)}")
for b in batches:
    print(f"ID: {b.id}, Section: {b.section}, Students: {len(b.students)}")

db.close()
