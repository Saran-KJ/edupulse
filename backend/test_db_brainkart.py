from database import SessionLocal
from models import LearningResource

db = SessionLocal()
resources = db.query(LearningResource).filter(LearningResource.tags.like('%BrainKart%')).limit(10).all()

print("BrainKart Resources in DB:")
for r in resources:
    print(f"- {r.title} | {r.subject_code} | {r.type} | {r.resource_level}")

print(f"Total BrainKart resources: {db.query(LearningResource).filter(LearningResource.tags.like('%BrainKart%')).count()}")
