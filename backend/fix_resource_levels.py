from database import SessionLocal
from models import LearningResource

def fix_resource_levels():
    db = SessionLocal()
    try:
        # Update all Drive links to be 'Basic' and 'High' risk minimum
        # This ensures they are visible to everyone (High, Medium, and Low risk students)
        resources = db.query(LearningResource).filter(
            LearningResource.url.ilike('%drive.google.com%')
        ).all()
        
        print(f"🔄 Updating {len(resources)} Drive resources to 'Basic' level...")
        updated_count = 0
        for r in resources:
            r.resource_level = 'Basic'
            r.min_risk_level = 'High'  # High risk students can see it, and Medium/Low follow
            updated_count += 1
        
        db.commit()
        print(f"✨ SUCCESS: {updated_count} resources are now visible to High-Risk students.")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    fix_resource_levels()
