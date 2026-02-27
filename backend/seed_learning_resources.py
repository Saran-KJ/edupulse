from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models import LearningResource, StudentLearningProgress, Base
import datetime

def seed_learning_resources():
    db = SessionLocal()
    try:
        Base.metadata.create_all(bind=engine)
        
        # Drop existing resources to reseed with new schema
        existing = db.query(LearningResource).count()
        if existing > 0:
            print(f"Clearing {existing} existing resources to reseed with unit/level data...")
            db.query(StudentLearningProgress).delete()
            db.query(LearningResource).delete()
            db.commit()

        resources = [
            # ── BASIC (High Risk - Academic Recovery) ──────────────────
            # Unit 1
            LearningResource(
                title="Unit 1 - Fundamentals Crash Course",
                description="Quick revision of core concepts from Unit 1.",
                url="https://www.youtube.com/watch?v=fundamentals-u1",
                type="video", tags="general,unit1,basics", dept=None,
                unit="1", resource_level="Basic", language="English"
            ),
            LearningResource(
                title="Unit 1 - Key Definitions & Formulas",
                description="One-page summary of essential definitions for Unit 1.",
                url="https://example.com/unit1-basics",
                type="article", tags="general,unit1,basics", dept=None,
                unit="1", resource_level="Basic", language="English"
            ),
            # Unit 2
            LearningResource(
                title="Unit 2 - Basics Explained Simply",
                description="Beginner-friendly explanation of Unit 2 topics.",
                url="https://www.youtube.com/watch?v=basics-u2",
                type="video", tags="general,unit2,basics", dept=None,
                unit="2", resource_level="Basic", language="English"
            ),
            LearningResource(
                title="Unit 2 - Practice Quiz (Basic)",
                description="Simple quiz to test Unit 2 fundamentals.",
                url="https://example.com/unit2-quiz-basic",
                type="quiz", tags="general,unit2,basics", dept=None,
                unit="2", resource_level="Basic", language="English"
            ),
            # Unit 3
            LearningResource(
                title="Unit 3 - Getting Started",
                description="Introduction to Unit 3 concepts for beginners.",
                url="https://example.com/unit3-basics",
                type="article", tags="general,unit3,basics", dept=None,
                unit="3", resource_level="Basic", language="English"
            ),
            # Unit 4
            LearningResource(
                title="Unit 4 - Core Concepts Review",
                description="Review all fundamental concepts in Unit 4.",
                url="https://www.youtube.com/watch?v=basics-u4",
                type="video", tags="general,unit4,basics", dept=None,
                unit="4", resource_level="Basic", language="English"
            ),
            # Unit 5
            LearningResource(
                title="Unit 5 - Simplified Walkthrough",
                description="Step-by-step walkthrough of Unit 5 basics.",
                url="https://example.com/unit5-basics",
                type="article", tags="general,unit5,basics", dept=None,
                unit="5", resource_level="Basic", language="English"
            ),
            # Multi-unit basic
            LearningResource(
                title="Units 1-2 Combined Review (Basic)",
                description="Quick review covering essential topics from Units 1 and 2.",
                url="https://example.com/u12-basic",
                type="video", tags="general,unit1,unit2,basics", dept=None,
                unit="1,2", resource_level="Basic", language="English"
            ),
            LearningResource(
                title="Units 3-4 Combined Review (Basic)",
                description="Quick review covering essential topics from Units 3 and 4.",
                url="https://example.com/u34-basic",
                type="video", tags="general,unit3,unit4,basics", dept=None,
                unit="3,4", resource_level="Basic", language="English"
            ),

            # ── INTERMEDIATE (Medium Risk - Academic Improvement) ────
            # Unit 1
            LearningResource(
                title="Unit 1 - Detailed Concepts & Examples",
                description="In-depth explanation with worked examples for Unit 1.",
                url="https://example.com/unit1-intermediate",
                type="article", tags="general,unit1,intermediate", dept=None,
                unit="1", resource_level="Intermediate", language="English"
            ),
            # Unit 2
            LearningResource(
                title="Unit 2 - Problem Solving Workshop",
                description="Practice problems with solutions for Unit 2.",
                url="https://example.com/unit2-problems",
                type="course", tags="general,unit2,intermediate", dept=None,
                unit="2", resource_level="Intermediate", language="English"
            ),
            # Unit 3
            LearningResource(
                title="Unit 3 - Intermediate Practice Set",
                description="Medium-difficulty practice questions for Unit 3.",
                url="https://example.com/unit3-practice",
                type="quiz", tags="general,unit3,intermediate", dept=None,
                unit="3", resource_level="Intermediate", language="English"
            ),
            # Unit 4
            LearningResource(
                title="Unit 4 - Concept Deepening",
                description="Go deeper into the core topics of Unit 4.",
                url="https://example.com/unit4-intermediate",
                type="video", tags="general,unit4,intermediate", dept=None,
                unit="4", resource_level="Intermediate", language="English"
            ),
            # Unit 5
            LearningResource(
                title="Unit 5 - Applied Concepts",
                description="Application-oriented study material for Unit 5.",
                url="https://example.com/unit5-intermediate",
                type="article", tags="general,unit5,intermediate", dept=None,
                unit="5", resource_level="Intermediate", language="English"
            ),
            # Multi-unit intermediate
            LearningResource(
                title="CIA 1 Preparation - Units 1 & 2",
                description="Comprehensive revision for CIA 1 covering Units 1 and 2.",
                url="https://example.com/cia1-prep",
                type="course", tags="general,unit1,unit2,intermediate", dept=None,
                unit="1,2", resource_level="Intermediate", language="English"
            ),
            LearningResource(
                title="CIA 2 Preparation - Units 3 & 4",
                description="Comprehensive revision for CIA 2 covering Units 3 and 4.",
                url="https://example.com/cia2-prep",
                type="course", tags="general,unit3,unit4,intermediate", dept=None,
                unit="3,4", resource_level="Intermediate", language="English"
            ),

            # ── ADVANCED (Low Risk - Academic Enhancement) ───────────
            # Unit 1
            LearningResource(
                title="Unit 1 - Advanced Topics & Research",
                description="Explore cutting-edge topics beyond the syllabus for Unit 1.",
                url="https://example.com/unit1-advanced",
                type="article", tags="general,unit1,advanced", dept=None,
                unit="1", resource_level="Advanced", language="English"
            ),
            # Unit 2
            LearningResource(
                title="Unit 2 - Challenging Problem Set",
                description="University-level challenging problems for Unit 2.",
                url="https://example.com/unit2-advanced",
                type="quiz", tags="general,unit2,advanced", dept=None,
                unit="2", resource_level="Advanced", language="English"
            ),
            # Unit 3
            LearningResource(
                title="Unit 3 - Advanced Applications",
                description="Real-world applications and case studies for Unit 3.",
                url="https://example.com/unit3-advanced",
                type="course", tags="general,unit3,advanced", dept=None,
                unit="3", resource_level="Advanced", language="English"
            ),
            # Unit 4
            LearningResource(
                title="Unit 4 - Deep Dive & Projects",
                description="Project-based learning for advanced Unit 4 topics.",
                url="https://example.com/unit4-advanced",
                type="video", tags="general,unit4,advanced", dept=None,
                unit="4", resource_level="Advanced", language="English"
            ),
            # Unit 5
            LearningResource(
                title="Unit 5 - Mastery Level Content",
                description="Expert-level content and practice for Unit 5.",
                url="https://example.com/unit5-advanced",
                type="article", tags="general,unit5,advanced", dept=None,
                unit="5", resource_level="Advanced", language="English"
            ),
            # Full syllabus advanced
            LearningResource(
                title="Model Exam Mastery - All Units",
                description="Advanced preparation covering all 5 units for model exam level.",
                url="https://example.com/model-advanced",
                type="course", tags="general,all-units,advanced", dept=None,
                unit="1,2,3,4,5", resource_level="Advanced", language="English"
            ),

            # ── SKILL DEVELOPMENT RESOURCES ──────────────────────────
            # Communication
            LearningResource(
                title="Effective Communication Skills",
                description="Master verbal and written communication for academic and professional success.",
                url="https://www.coursera.org/learn/communication-skills",
                type="course", tags="skill,communication", dept=None,
                skill_category="Communication", language="English"
            ),
            LearningResource(
                title="Public Speaking Mastery",
                description="Overcome stage fear and deliver impactful presentations.",
                url="https://www.youtube.com/watch?v=public-speaking",
                type="video", tags="skill,communication,speaking", dept=None,
                skill_category="Communication", language="English"
            ),
            LearningResource(
                title="Technical Writing Guide",
                description="Learn to write clear technical reports and documentation.",
                url="https://example.com/technical-writing",
                type="article", tags="skill,communication,writing", dept=None,
                skill_category="Communication", language="English"
            ),
            # Programming
            LearningResource(
                title="Python Programming for Beginners",
                description="Complete Python course from basics to intermediate.",
                url="https://www.python.org/about/gettingstarted/",
                type="course", tags="skill,programming,python", dept=None,
                skill_category="Programming", language="English"
            ),
            LearningResource(
                title="Data Structures & Algorithms",
                description="Build problem-solving skills with DSA fundamentals.",
                url="https://www.geeksforgeeks.org/data-structures/",
                type="article", tags="skill,programming,dsa", dept=None,
                skill_category="Programming", language="English"
            ),
            LearningResource(
                title="Web Development Crash Course",
                description="Learn HTML, CSS, and JavaScript in one course.",
                url="https://www.youtube.com/watch?v=web-dev-crash",
                type="video", tags="skill,programming,web", dept=None,
                skill_category="Programming", language="English"
            ),
            # Aptitude
            LearningResource(
                title="Quantitative Aptitude Practice",
                description="Practice aptitude questions for placements and competitive exams.",
                url="https://www.indiabix.com/aptitude/questions-and-answers/",
                type="quiz", tags="skill,aptitude,quantitative", dept=None,
                skill_category="Aptitude", language="English"
            ),
            LearningResource(
                title="Logical Reasoning Masterclass",
                description="Develop logical thinking and reasoning abilities.",
                url="https://example.com/logical-reasoning",
                type="course", tags="skill,aptitude,reasoning", dept=None,
                skill_category="Aptitude", language="English"
            ),
            LearningResource(
                title="Verbal Ability & Comprehension",
                description="Improve English verbal ability for competitive exams.",
                url="https://example.com/verbal-ability",
                type="article", tags="skill,aptitude,verbal", dept=None,
                skill_category="Aptitude", language="English"
            ),
            # Critical Thinking
            LearningResource(
                title="Critical Thinking & Problem Solving",
                description="Learn frameworks for systematic problem solving.",
                url="https://example.com/critical-thinking",
                type="course", tags="skill,critical-thinking", dept=None,
                skill_category="Critical Thinking", language="English"
            ),
            # Leadership
            LearningResource(
                title="Student Leadership Development",
                description="Develop leadership skills for team projects and organizations.",
                url="https://example.com/leadership",
                type="video", tags="skill,leadership", dept=None,
                skill_category="Leadership", language="English"
            ),

            # ── TAMIL LANGUAGE RESOURCES ─────────────────────────────
            LearningResource(
                title="அலகு 1 - அடிப்படைகள் (Unit 1 Basics)",
                description="அலகு 1 அடிப்படை கருத்துக்களின் எளிய விளக்கம்.",
                url="https://example.com/unit1-basic-ta",
                type="video", tags="general,unit1,basics,tamil", dept=None,
                unit="1", resource_level="Basic", language="Tamil"
            ),
            LearningResource(
                title="அலகு 2 - அடிப்படைகள் (Unit 2 Basics)",
                description="அலகு 2 அடிப்படை கருத்துக்களின் எளிய விளக்கம்.",
                url="https://example.com/unit2-basic-ta",
                type="video", tags="general,unit2,basics,tamil", dept=None,
                unit="2", resource_level="Basic", language="Tamil"
            ),
        ]

        db.add_all(resources)
        db.commit()
        print(f"Successfully seeded {len(resources)} learning resources with unit/level/skill data.")

    except Exception as e:
        print(f"Error seeding learning resources: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_learning_resources()
