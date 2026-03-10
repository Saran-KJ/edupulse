import sys
sys.path.insert(0, '.')
from config import get_settings
from sqlalchemy import create_engine, text

settings = get_settings()
engine = create_engine(settings.database_url)

# Test the exact same query as getAllSubjectResources for CS3591
subject_code = 'CS3591'
dept = 'CSE'

with engine.connect() as conn:
    # Main query
    result = conn.execute(text("""
        SELECT title, subject_code, tags, dept, unit, resource_level
        FROM learning_resources
        WHERE (dept = :dept OR dept IS NULL)
        AND (subject_code = :sc OR subject_code IS NULL)
        AND (language = 'English' OR language = 'English')
        ORDER BY tags
        LIMIT 20
    """), {"dept": dept, "sc": subject_code})
    
    rows = result.fetchall()
    print(f"Resources for {subject_code}:")
    poriyaan = 0
    brainkart = 0
    for row in rows:
        tag_source = "BrainKart" if "BrainKart" in str(row[2]) else "Poriyaan"
        print(f"  [{tag_source}] {row[1]} | {row[0][:60]}")
        if "BrainKart" in str(row[2]):
            brainkart += 1
        else:
            poriyaan += 1
    
    # Get total counts
    count_result = conn.execute(text("""
        SELECT 
            COUNT(CASE WHEN tags LIKE '%BrainKart%' THEN 1 END) as brainkart,
            COUNT(CASE WHEN tags LIKE '%Poriyaan%' THEN 1 END) as poriyaan
        FROM learning_resources
        WHERE (dept = :dept OR dept IS NULL)
        AND (subject_code = :sc OR subject_code IS NULL)
    """), {"dept": dept, "sc": subject_code})
    
    counts = count_result.fetchone()
    print(f"\nTotal for {subject_code}: BrainKart={counts[0]}, Poriyaan={counts[1]}")
