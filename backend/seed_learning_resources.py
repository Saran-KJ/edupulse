from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models import LearningResource, Base
import datetime

def seed_learning_resources():
    db = SessionLocal()
    try:
        # Create table if not exists (should be handled by main/init_db but good to ensure here)
        Base.metadata.create_all(bind=engine)
        
        # Check if resources already exist
        count = db.query(LearningResource).count()
        if count > 0:
            print(f"Learning resources already seeded ({count} found). Skipping.")
            return

        resources = [
            # General Resources
            LearningResource(
                title="Effective Time Management for Students",
                description="Learn how to balance study, sleep, and social life.",
                url="https://www.youtube.com/watch?v=F3J5Z8s5s4o",
                type="video",
                tags="general,productivity,soft-skills",
                dept=None,
                min_risk_level=None
            ),
            LearningResource(
                title="How to Ace Your Exams",
                description="Study tips and strategies for better grades.",
                url="https://www.youtube.com/watch?v=p60rN9JEapg",
                type="video",
                tags="general,study-skills",
                dept=None,
                min_risk_level=None
            ),
            
            # CSE Resources
            LearningResource(
                title="Introduction to Algorithms (MIT)",
                description="Comprehensive course on algorithms.",
                url="https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-fall-2011/",
                type="course",
                tags="cse,algorithms,advanced",
                dept="CSE",
                min_risk_level="Low"
            ),
            LearningResource(
                title="Data Structures Basics",
                description="Fundamental data structures explained simply.",
                url="https://www.geeksforgeeks.org/data-structures/",
                type="article",
                tags="cse,data-structures,remedial",
                dept="CSE",
                min_risk_level="High"
            ),
             LearningResource(
                title="Python for Beginners",
                description="Learn Python from scratch.",
                url="https://www.python.org/about/gettingstarted/",
                type="article",
                tags="cse,python,remedial",
                dept="CSE",
                min_risk_level="Medium"
            ),

            # ECE Resources
            LearningResource(
                title="Circuit Theory Basics",
                description="Understanding voltage, current, and resistance.",
                url="https://www.allaboutcircuits.com/textbook/direct-current/chpt-1/voltage-current-resistance/",
                type="article",
                tags="ece,circuits,remedial",
                dept="ECE",
                min_risk_level="High"
            ),
            LearningResource(
                title="Digital Signal Processing (NPTEL)",
                description="Advanced concepts in DSP.",
                url="https://nptel.ac.in/courses/117102060",
                type="video",
                tags="ece,dsp,advanced",
                dept="ECE",
                min_risk_level="Low"
            ),
            
            # High Risk General
            LearningResource(
                title="Academic Counseling: Getting Back on Track",
                description="Resources for students facing academic challenges.",
                url="https://example.com/counseling",
                type="article",
                tags="general,support,remedial",
                dept=None,
                min_risk_level="High"
            ),
        ]
        
        db.add_all(resources)
        db.commit()
        print(f"Successfully seeded {len(resources)} learning resources.")
        
    except Exception as e:
        print(f"Error seeding learning resources: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_learning_resources()
