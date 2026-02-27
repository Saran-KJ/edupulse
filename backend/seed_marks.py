"""
seed_marks.py
--------------
Seeds realistic mark data for existing CSE students using actual subject codes
from the subjects table.

Usage:
  python seed_marks.py

Clears existing marks for seeded students then re-inserts fresh data.
"""
import random
from database import SessionLocal
import models
from datetime import datetime

random.seed(42)

GRADE_THRESHOLDS = [
    (90, 'O'),
    (80, 'A+'),
    (70, 'A'),
    (60, 'B+'),
    (50, 'B'),
    (40, 'C'),
    (0,  'U'),
]

def score_to_grade(score):
    for threshold, grade in GRADE_THRESHOLDS:
        if score >= threshold:
            return grade
    return 'U'

def rand_internal(capability):
    """Generate internal mark components for a given capability (0-1)."""
    def r(maxval, sigma=None):
        sigma = sigma or maxval * 0.15
        return round(max(0, min(maxval, random.gauss(maxval * capability, sigma))), 1)

    st1, st2 = r(20, 3), r(20, 3)
    st3, st4 = r(20, 3), r(20, 3)
    a1, a2 = r(10, 1.5), r(10, 1.5)
    a3, a4, a5 = r(10, 1.5), r(10, 1.5), r(10, 1.5)
    cia1 = r(60, 8)
    cia2 = r(60, 8)
    model = r(100, 12)

    return {
        'slip_test_1': st1, 'slip_test_2': st2,
        'slip_test_3': st3, 'slip_test_4': st4,
        'assignment_1': a1, 'assignment_2': a2,
        'assignment_3': a3, 'assignment_4': a4, 'assignment_5': a5,
        'cia_1': cia1, 'cia_2': cia2,
        'model': model,
    }

def internal_final(components):
    st_avg1 = (components['slip_test_1'] + components['slip_test_2']) / 2
    a_avg1  = (components['assignment_1'] + components['assignment_2']) / 2
    i1 = (0.3 * st_avg1 + 0.2 * a_avg1 + 0.5 * components['cia_1']) / 38 * 100

    st_avg2 = (components['slip_test_3'] + components['slip_test_4']) / 2
    a_avg2  = (components['assignment_3'] + components['assignment_4'] + components['assignment_5']) / 3
    i2 = (0.25 * st_avg2 + 0.15 * a_avg2 + 0.3 * components['cia_2'] + 0.3 * components['model']) / 54.5 * 100

    return 0.4 * i1 + 0.6 * i2

# Anna University semester number → Roman numeral mapping
SEM_MAP = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII'}

# Student profiles for realistic capability distribution
PROFILES = [
    {'type': 'Excellent', 'prob': 0.2, 'capability': (0.85, 0.98)},
    {'type': 'Good',      'prob': 0.4, 'capability': (0.70, 0.88)},
    {'type': 'Average',   'prob': 0.3, 'capability': (0.52, 0.72)},
    {'type': 'Struggling','prob': 0.1, 'capability': (0.30, 0.55)},
]

def pick_profile():
    r = random.random()
    cumulative = 0
    for p in PROFILES:
        cumulative += p['prob']
        if r < cumulative:
            return p
    return PROFILES[-1]

def get_grade(capability):
    """Simulate a university exam grade from capability."""
    score = random.gauss(capability * 100, 8)
    score = max(0, min(100, score))
    return score_to_grade(score), score

def seed():
    db = SessionLocal()
    try:
        # Fetch all CSE students
        students = db.query(models.StudentCSE).all()
        if not students:
            print("No CSE students found. Please add students first.")
            return

        print(f"Found {len(students)} CSE students.")

        # Fetch subjects grouped by semester
        all_subjects = db.query(models.Subject).all()
        sem_subjects = {}
        for s in all_subjects:
            sem = s.semester
            if sem not in sem_subjects:
                sem_subjects[sem] = []
            sem_subjects[sem].append(s)

        print(f"Found subjects in semesters: {list(sem_subjects.keys())}")

        total_inserted = 0
        total_skipped = 0

        for student in students:
            # Assign a profile to each student (deterministic by reg_no)
            random.seed(hash(student.reg_no) % (2**32))
            profile = pick_profile()
            base_cap = random.uniform(*profile['capability'])

            # Determine how many semesters to seed (based on student's year)
            year = student.year or 1
            semesters_to_seed = list(range(1, min(year * 2 + 1, 9)))  # e.g., Year 2 → sems 1-4

            for sem_num in semesters_to_seed:
                roman = SEM_MAP.get(sem_num)
                if not roman:
                    continue
                subjects = sem_subjects.get(roman, [])
                if not subjects:
                    print(f"  No subjects found for semester {roman}, skipping.")
                    continue

                # Slight variation per semester (simulate improvement/decline)
                sem_cap = max(0.3, min(1.0, base_cap + random.uniform(-0.08, 0.08)))

                for subj in subjects:
                    # Skip zero-credit subjects (like Induction Programme)
                    if not subj.credits or subj.credits == 0:
                        continue

                    existing = db.query(models.Mark).filter(
                        models.Mark.reg_no == student.reg_no,
                        models.Mark.subject_code == subj.subject_code,
                        models.Mark.semester == sem_num,
                    ).first()
                    if existing:
                        total_skipped += 1
                        continue

                    # Subject-specific capability tweak
                    subj_cap = max(0.2, min(1.0, sem_cap + random.uniform(-0.1, 0.1)))

                    components = rand_internal(subj_cap)

                    # University grade — only for completed semesters
                    completed_sems = set(range(1, year * 2))  # semesters before current
                    if sem_num in completed_sems:
                        grade, _ = get_grade(subj_cap)
                    else:
                        grade = None  # current semester — no result yet

                    mark = models.Mark(
                        reg_no=student.reg_no,
                        student_name=student.name,
                        dept='CSE',
                        year=year,
                        section=student.section or 'A',
                        semester=sem_num,
                        subject_code=subj.subject_code,
                        subject_title=subj.subject_title,
                        university_result_grade=grade,
                        **components,
                    )
                    db.add(mark)
                    total_inserted += 1

            db.commit()
            print(f"  [OK] {student.name} ({student.reg_no}) - {profile['type']} profile, {len(semesters_to_seed)} sem(s)")

        print(f"\nDone! Inserted {total_inserted} marks, skipped {total_skipped} (already exist).")

    except Exception as e:
        db.rollback()
        import traceback
        traceback.print_exc()
        print(f"Error during seeding: {e}")
    finally:
        db.close()

if __name__ == '__main__':
    print("=" * 55)
    print("  EduPulse - Realistic Marks Seed Script")
    print("=" * 55)
    seed()
