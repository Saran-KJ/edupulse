"""Diagnostic script: shows all scheduled_quizzes and matches against students."""
import sys
sys.path.insert(0, '.')
from database import SessionLocal
import models
from datetime import datetime

db = SessionLocal()
try:
    now_utc = datetime.utcnow()
    now_local = datetime.now()
    
    print(f"Current time (local): {now_local}")
    print(f"Current time (UTC):   {now_utc}")
    print()

    # 1. Show ALL scheduled quizzes (no filter)
    all_quizzes = db.query(models.ScheduledQuiz).all()
    print(f"=== ALL Scheduled Quizzes ({len(all_quizzes)} total) ===")
    for q in all_quizzes:
        print(f"  ID={q.id} dept={q.dept} year={q.year} section={q.section}")
        print(f"    subject={q.subject_code} unit={q.unit_number} type={q.assessment_type}")
        print(f"    start_time={q.start_time} deadline={q.deadline}")
        print(f"    is_active={q.is_active}")
        # Check deadline vs now
        print(f"    deadline > now_utc? {q.deadline > now_utc}")
        print(f"    deadline > now_local? {q.deadline > now_local}")
        if q.start_time:
            print(f"    start_time <= now_utc? {q.start_time <= now_utc}")
            print(f"    start_time <= now_local? {q.start_time <= now_local}")
        else:
            print(f"    start_time is None (should always show)")
        print()

    print()
    # 2. Show first student from each dept to find match
    student_models = [
        models.StudentCSE, models.StudentECE, models.StudentEEE,
        models.StudentMECH, models.StudentCIVIL, models.StudentBIO, models.StudentAIDS
    ]
    print("=== Students with matching quizzes ===")
    for model in student_models:
        students = db.query(model).all()
        for student in students:
            for q in all_quizzes:
                if q.dept == student.dept and q.year == int(student.year) and q.section == student.section:
                    print(f"  MATCH: Student {student.reg_no} ({student.dept} Y{student.year} {student.section}) -> Quiz ID={q.id}")
                    # Check attempt
                    attempted = db.query(models.StudentQuizAttempt).filter(
                        models.StudentQuizAttempt.reg_no == student.reg_no,
                        models.StudentQuizAttempt.unit == q.unit_number,
                    ).first()
                    print(f"    Has attempted? {attempted is not None}")

    print()
    # 3. Run the exact query from the fixed endpoint
    print("=== Pending quizzes using fixed query (UTC) ===")
    from sqlalchemy import or_
    now = datetime.utcnow()
    scheduled = db.query(models.ScheduledQuiz).filter(
        models.ScheduledQuiz.is_active == 1,
        models.ScheduledQuiz.deadline > now,
        or_(
            models.ScheduledQuiz.start_time <= now,
            models.ScheduledQuiz.start_time.is_(None)
        )
    ).all()
    print(f"  Found {len(scheduled)} active quizzes (deadline in future, start_time passed or null)")
    for q in scheduled:
        print(f"    ID={q.id} dept={q.dept} year={q.year} sec={q.section} subject={q.subject_code}")

    print()
    print("=== Pending quizzes using LOCAL time ===")
    now_l = datetime.now()
    scheduled_l = db.query(models.ScheduledQuiz).filter(
        models.ScheduledQuiz.is_active == 1,
        models.ScheduledQuiz.deadline > now_l,
        or_(
            models.ScheduledQuiz.start_time <= now_l,
            models.ScheduledQuiz.start_time.is_(None)
        )
    ).all()
    print(f"  Found {len(scheduled_l)} active quizzes with local time comparison")
    for q in scheduled_l:
        print(f"    ID={q.id} dept={q.dept} year={q.year} sec={q.section} subject={q.subject_code}")

finally:
    db.close()
