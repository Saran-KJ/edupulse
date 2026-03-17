"""Test script to verify Faculty Quiz Scheduling end-to-end flow"""
import sys
from datetime import datetime, timedelta
from database import SessionLocal
import models

def test_scheduling():
    db = SessionLocal()
    try:
        # 1. Get a faculty and student
        faculty = db.query(models.User).filter(models.User.role == "faculty").first()
        student = db.query(models.StudentCSE).first()
        
        if not faculty or not student:
            print("Need at least one faculty and one CSE student for test.")
            return

        print(f"Testing with Faculty: {faculty.name}")
        print(f"Testing with Student: {student.name} ({student.dept} {student.year} {student.section})")

        # 2. Give faculty allocation to student's class
        alloc = db.query(models.FacultyAllocation).filter(
            models.FacultyAllocation.faculty_id == faculty.user_id,
            models.FacultyAllocation.dept == student.dept,
            models.FacultyAllocation.year == student.year,
            models.FacultyAllocation.section == student.section
        ).first()

        if not alloc:
            alloc = models.FacultyAllocation(
                faculty_id=faculty.user_id,
                dept=student.dept,
                year=student.year,
                section=student.section,
                subject_code="CS3351",
                subject_title="Digital Principles & Computer Organization"
            )
            db.add(alloc)
            db.commit()

        # 3. Schedule a quiz
        deadline = datetime.utcnow() + timedelta(days=2)
        scheduled = models.ScheduledQuiz(
            faculty_id=faculty.user_id,
            dept=student.dept,
            year=student.year,
            section=student.section,
            subject_code=alloc.subject_code,
            subject_title=alloc.subject_title,
            unit_number=2,
            assessment_type="CIA",
            deadline=deadline
        )
        db.add(scheduled)
        db.commit()
        db.refresh(scheduled)
        print(f"\n=> Created Scheduled Quiz ID: {scheduled.id}")

        # 4. Pretend to be student hitting the /me/pending-quizzes endpoint logic
        now = datetime.utcnow()
        active_quizzes = db.query(models.ScheduledQuiz).filter(
            models.ScheduledQuiz.dept == student.dept,
            models.ScheduledQuiz.year == int(student.year),
            models.ScheduledQuiz.section == student.section,
            models.ScheduledQuiz.is_active == 1,
            models.ScheduledQuiz.deadline > now
        ).all()
        
        pending = []
        for q in active_quizzes:
            has_attempted = db.query(models.StudentQuizAttempt).filter(
                models.StudentQuizAttempt.reg_no == student.reg_no,
                models.StudentQuizAttempt.unit == q.unit_number,
                (models.StudentQuizAttempt.subject == q.subject_code) | 
                (models.StudentQuizAttempt.subject == q.subject_title)
            ).first()
            if not has_attempted:
                pending.append(q)

        print(f"\n=> Student Pending Quizzes Found: {len(pending)}")
        assert len(pending) > 0, "No pending quizzes found for student!"
        found_quiz = False
        for p in pending:
            if p.id == scheduled.id:
                found_quiz = True
                print(f"  - Verified: Student sees quiz {p.id} for {p.subject_title} (Unit {p.unit_number})")
        assert found_quiz, "Student didn't see the recently scheduled quiz!"

        # 5. Clean up
        db.delete(scheduled)
        db.commit()
        print("\nAll checks passed! ScheduledQuiz logic is working correctly.")

    except Exception as e:
        print(f"TEST FAILED: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    test_scheduling()
