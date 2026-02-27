"""
Seed script for Anna University R2021 B.E CSE Subjects (Core + PEC + OEC)
Creates the subjects table and populates it with all curriculum data.
"""

from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models

def seed_subjects():
    """Seed the subjects table with Anna University R2021 B.E CSE curriculum data."""
    db = SessionLocal()

    try:
        # Create the subjects table if it doesn't exist
        models.Subject.__table__.create(bind=engine, checkfirst=True)
        print("✓ Subjects table ready")

        # Check if subjects already exist
        existing_count = db.query(models.Subject).count()
        if existing_count > 0:
            print(f"⚠ Subjects table already has {existing_count} records.")
            response = input("Do you want to clear and re-seed? (y/n): ").strip().lower()
            if response != 'y':
                print("Skipping seed.")
                return
            db.query(models.Subject).delete()
            db.commit()
            print("✓ Cleared existing subjects")

        subjects_data = [
            # ===== SEMESTER I =====
            ("I", "IP3151", "Induction Programme", "CORE", 0),
            ("I", "HS3152", "Professional English - I", "CORE", 3),
            ("I", "MA3151", "Matrices and Calculus", "CORE", 4),
            ("I", "PH3151", "Engineering Physics", "CORE", 3),
            ("I", "CY3151", "Engineering Chemistry", "CORE", 3),
            ("I", "GE3151", "Problem Solving and Python Programming", "CORE", 3),
            ("I", "GE3152", "Heritage of Tamils", "CORE", 1),
            ("I", "GE3171", "Problem Solving and Python Programming Laboratory", "LAB", 2),
            ("I", "BS3171", "Physics and Chemistry Laboratory", "LAB", 2),
            ("I", "GE3172", "English Laboratory", "LAB", 1),

            # ===== SEMESTER II =====
            ("II", "HS3252", "Professional English - II", "CORE", 2),
            ("II", "MA3251", "Statistics and Numerical Methods", "CORE", 4),
            ("II", "PH3256", "Physics for Information Science", "CORE", 3),
            ("II", "BE3251", "Basic Electrical and Electronics Engineering", "CORE", 3),
            ("II", "GE3251", "Engineering Graphics", "CORE", 4),
            ("II", "CS3251", "Programming in C", "CORE", 3),
            ("II", "GE3252", "Tamils and Technology", "CORE", 1),
            ("II", "GE3271", "Engineering Practices Laboratory", "LAB", 2),
            ("II", "CS3271", "Programming in C Laboratory", "LAB", 2),
            ("II", "GE3272", "Communication Laboratory", "LAB", 2),

            # ===== SEMESTER III =====
            ("III", "MA3354", "Discrete Mathematics", "CORE", 4),
            ("III", "CS3351", "Digital Principles and Computer Organization", "CORE", 4),
            ("III", "CS3352", "Foundations of Data Science", "CORE", 3),
            ("III", "CS3301", "Data Structures", "CORE", 3),
            ("III", "CS3391", "Object Oriented Programming", "CORE", 3),
            ("III", "CS3311", "Data Structures Laboratory", "LAB", 1.5),
            ("III", "CS3381", "Object Oriented Programming Laboratory", "LAB", 1.5),
            ("III", "CS3361", "Data Science Laboratory", "LAB", 2),
            ("III", "GE3361", "Professional Development", "EEC", 1),

            # ===== SEMESTER IV =====
            ("IV", "CS3452", "Theory of Computation", "CORE", 3),
            ("IV", "CS3491", "Artificial Intelligence and Machine Learning", "CORE", 4),
            ("IV", "CS3492", "Database Management Systems", "CORE", 3),
            ("IV", "CS3401", "Algorithms", "CORE", 4),
            ("IV", "CS3451", "Introduction to Operating Systems", "CORE", 3),
            ("IV", "GE3451", "Environmental Sciences and Sustainability", "CORE", 2),
            ("IV", "CS3461", "Operating Systems Laboratory", "LAB", 1.5),
            ("IV", "CS3481", "Database Management Systems Laboratory", "LAB", 1.5),

            # ===== SEMESTER V =====
            ("V", "CS3591", "Computer Networks", "CORE", 4),
            ("V", "CS3501", "Compiler Design", "CORE", 4),
            ("V", "CB3491", "Cryptography and Cyber Security", "CORE", 3),
            ("V", "CS3551", "Distributed Computing", "CORE", 3),

            # ===== SEMESTER VI =====
            ("VI", "CCS356", "Object Oriented Software Engineering", "CORE", 4),
            ("VI", "CS3691", "Embedded Systems and IoT", "CORE", 4),

            # ===== SEMESTER VII =====
            ("VII", "GE3791", "Human Values and Ethics", "CORE", 2),
            ("VII", "CS3711", "Summer Internship", "EEC", 2),

            # ===== SEMESTER VIII =====
            ("VIII", "CS3811", "Project Work / Internship", "EEC", 10),

            # ===== PROFESSIONAL ELECTIVES (PEC) =====
            ("PEC", "CCS346", "Exploratory Data Analysis", "PEC", 3),
            ("PEC", "CCS360", "Recommender Systems", "PEC", 3),
            ("PEC", "CCS355", "Neural Networks and Deep Learning", "PEC", 3),
            ("PEC", "CCS369", "Text and Speech Analysis", "PEC", 3),
            ("PEC", "CCS349", "Image and Video Analytics", "PEC", 3),
            ("PEC", "CCS338", "Computer Vision", "PEC", 3),
            ("PEC", "CCS334", "Big Data Analytics", "PEC", 3),
            ("PEC", "CCS375", "Web Technologies", "PEC", 3),
            ("PEC", "CCS332", "App Development", "PEC", 3),
            ("PEC", "CCS370", "UI and UX Design", "PEC", 3),
            ("PEC", "CCS366", "Software Testing and Automation", "PEC", 3),
            ("PEC", "CCS342", "DevOps", "PEC", 3),
            ("PEC", "CCS335", "Cloud Computing", "PEC", 3),
            ("PEC", "CCS344", "Ethical Hacking", "PEC", 3),
            ("PEC", "CCS351", "Modern Cryptography", "PEC", 3),

            # ===== OPEN ELECTIVES (OEC) =====
            ("OEC", "OAS351", "Space Science", "OEC", 3),
            ("OEC", "OIE351", "Introduction to Industrial Engineering", "OEC", 3),
            ("OEC", "OBT351", "Food, Nutrition and Health", "OEC", 3),
            ("OEC", "OCE351", "Environmental and Social Impact Assessment", "OEC", 3),
            ("OEC", "OEE351", "Renewable Energy Systems", "OEC", 3),
            ("OEC", "OMA351", "Graph Theory", "OEC", 3),
            ("OEC", "OHS351", "English for Competitive Examinations", "OEC", 3),
            ("OEC", "OMG352", "NGOs and Sustainable Development", "OEC", 3),
            ("OEC", "AU3791", "Electric and Hybrid Vehicles", "OEC", 3),
            ("OEC", "CRA332", "Drone Technologies", "OEC", 3),
        ]

        # Insert all subjects
        for sem, code, title, category, credits in subjects_data:
            subject = models.Subject(
                semester=sem,
                subject_code=code,
                subject_title=title,
                category=category,
                credits=credits
            )
            db.add(subject)

        db.commit()

        total = db.query(models.Subject).count()
        core_count = db.query(models.Subject).filter(models.Subject.category == "CORE").count()
        lab_count = db.query(models.Subject).filter(models.Subject.category == "LAB").count()
        pec_count = db.query(models.Subject).filter(models.Subject.category == "PEC").count()
        oec_count = db.query(models.Subject).filter(models.Subject.category == "OEC").count()
        eec_count = db.query(models.Subject).filter(models.Subject.category == "EEC").count()

        print("\n" + "=" * 60)
        print("✓ Anna University R2021 B.E CSE Subjects Seeded!")
        print("=" * 60)
        print(f"  Total Subjects : {total}")
        print(f"  CORE            : {core_count}")
        print(f"  LAB             : {lab_count}")
        print(f"  PEC             : {pec_count}")
        print(f"  OEC             : {oec_count}")
        print(f"  EEC             : {eec_count}")
        print("=" * 60)

    except Exception as e:
        print(f"✗ Error seeding subjects: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    print("EduPulse - Seed Anna University CSE Subjects")
    print("=" * 60)
    seed_subjects()
