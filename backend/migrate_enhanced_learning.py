"""
Migration script: Add new columns for enhanced personalized learning module.
- StudentBase tables: preferred_learning_type
- LearningResource: subject_code
- PersonalizedLearningPlan: practice_schedule, weekly_goals
"""
from database import engine
from sqlalchemy import text, inspect

def migrate():
    inspector = inspect(engine)
    
    # All student tables that inherit from StudentBase
    student_tables = [
        "students_cse", "students_ece", "students_eee",
        "students_mech", "students_civil", "students_bio", "students_aids"
    ]
    
    with engine.connect() as conn:
        # 1. Add preferred_learning_type to all student tables
        for table in student_tables:
            if table in inspector.get_table_names():
                columns = [col['name'] for col in inspector.get_columns(table)]
                if 'preferred_learning_type' not in columns:
                    conn.execute(text(
                        f'ALTER TABLE {table} ADD COLUMN preferred_learning_type VARCHAR(50) DEFAULT \'text\''
                    ))
                    print(f"  Added preferred_learning_type to {table}")
                else:
                    print(f"  preferred_learning_type already exists in {table}")
        
        # 2. Add subject_code to learning_resources
        if 'learning_resources' in inspector.get_table_names():
            columns = [col['name'] for col in inspector.get_columns('learning_resources')]
            if 'subject_code' not in columns:
                conn.execute(text(
                    'ALTER TABLE learning_resources ADD COLUMN subject_code VARCHAR(20)'
                ))
                print("  Added subject_code to learning_resources")
            else:
                print("  subject_code already exists in learning_resources")
        
        # 3. Add practice_schedule and weekly_goals to personalized_learning_plans
        if 'personalized_learning_plans' in inspector.get_table_names():
            columns = [col['name'] for col in inspector.get_columns('personalized_learning_plans')]
            if 'practice_schedule' not in columns:
                conn.execute(text(
                    'ALTER TABLE personalized_learning_plans ADD COLUMN practice_schedule TEXT'
                ))
                print("  Added practice_schedule to personalized_learning_plans")
            else:
                print("  practice_schedule already exists in personalized_learning_plans")
            
            if 'weekly_goals' not in columns:
                conn.execute(text(
                    'ALTER TABLE personalized_learning_plans ADD COLUMN weekly_goals TEXT'
                ))
                print("  Added weekly_goals to personalized_learning_plans")
            else:
                print("  weekly_goals already exists in personalized_learning_plans")
        
        conn.commit()
    
    print("\nMigration complete!")

if __name__ == "__main__":
    migrate()
