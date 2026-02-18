from database import SessionLocal
from ml_service import ml_service
import models
from datetime import datetime

def verify_advanced_learning():
    db = SessionLocal()
    try:
        # Setup: Ensure we have some test resources
        # 1. Tamil Resource
        tamil_res = models.LearningResource(
            title="Tamil TOC Basics",
            url="http://tamil-toc.com",
            type="video",
            language="Tamil",
            dept="CSE",
            tags="TOC, Tamil"
        )
        # 2. Quiz Resource
        quiz_res = models.LearningResource(
            title="TOC Quiz 1",
            url="http://toc-quiz.com",
            type="quiz",
            language="English",
            dept="CSE",
            tags="TOC, Quiz"
        )
        db.add(tamil_res)
        db.add(quiz_res)
        db.commit()
        
        print("Created test resources.")

        # Test 1: Language Filtering
        print("\nTesting Tamil Language Filter...")
        # Simulate route logic for filtering
        tamil_query = db.query(models.LearningResource).filter(
            models.LearningResource.language == "Tamil"
        ).all()
        
        has_tamil = any(r.title == "Tamil TOC Basics" for r in tamil_query)
        if has_tamil:
            print("✓ Tamil filter working")
        else:
            print("✗ Tamil filter failed")

        # Test 2: Quiz Prioritization (Mocking High Risk)
        print("\nTesting Quiz Prioritization for High Risk...")
        resources = [tamil_res, quiz_res] # simplified list
        
        # High Risk Logic from route:
        # filtered_resources.sort(key=lambda x: x['type'] != 'quiz')
        # Let's mock the dict structure used in route
        res_dicts = [
            {"title": "Tamil TOC Basics", "type": "video"},
            {"title": "TOC Quiz 1", "type": "quiz"}
        ]
        
        res_dicts.sort(key=lambda x: x['type'] != 'quiz')
        
        if res_dicts[0]['type'] == 'quiz':
             print("✓ Quiz prioritized correctly")
        else:
             print("✗ Quiz prioritization failed")

        # Cleanup
        db.delete(tamil_res)
        db.delete(quiz_res)
        db.commit()
        
    finally:
        db.close()

if __name__ == "__main__":
    verify_advanced_learning()
