from database import SessionLocal
from models import LearningResource, StudentLearningProgress

def remove_mock_resources():
    db = SessionLocal()
    start_id = 4847
    end_id = 4881
    
    try:
        print(f"Deleting progress records for resource IDs in range {start_id} to {end_id}...")
        db.query(StudentLearningProgress).filter(
            StudentLearningProgress.resource_id.between(start_id, end_id)
        ).delete(synchronize_session=False)
        
        print(f"Deleting learning resources with IDs in range {start_id} to {end_id}...")
        deleted_count = db.query(LearningResource).filter(
            LearningResource.resource_id.between(start_id, end_id)
        ).delete(synchronize_session=False)
        
        db.commit()
        print(f"Successfully deleted {deleted_count} learning resources.")
    except Exception as e:
        db.rollback()
        print(f"Error during deletion: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    remove_mock_resources()
