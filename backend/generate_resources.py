import psycopg2
import urllib.parse
import os

DB_URL = "postgresql://postgres:sk%4065@localhost:5432/edupulse"

def generate_resources_sql():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        cur.execute("SELECT subject_title FROM subjects")
        subjects = [row[0] for row in cur.fetchall()]
        conn.close()
    except Exception as e:
        print(f"Failed to connect to DB: {e}")
        return

    output_file = "insert_learning_resources.sql"
    
    # We will write raw SQL inserts.
    # Risk Mapping: LOW -> Advanced, MEDIUM -> Intermediate, HIGH -> Basic
    # Resource Types: Video, PDF, Visual Explanation
    
    risk_mapping = {
        'Low': 'Advanced',
        'Medium': 'Intermediate',
        'High': 'Basic'
    }
    
    resource_types = ['Video', 'PDF', 'Visual Explanation']
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("-- SQL Inserts for learning_resources table\n\n")
        
        for subject in subjects:
            f.write(f"-- Resources for: {subject}\n")
            
            # Unit 1 to 5
            for unit in range(1, 6):
                for risk_level, resource_level in risk_mapping.items():
                    for res_type in resource_types:
                        
                        # Generate a realistic Title
                        title = f"{subject} Unit {unit} {resource_level} {res_type} in Tamil"
                        
                        # Generate an open educational link (YouTube search or generic PDF search link)
                        if res_type == 'Video':
                            query = f"{subject} Unit {unit} {resource_level} Tamil"
                            link = f"https://www.youtube.com/results?search_query={urllib.parse.quote_plus(query)}"
                        elif res_type == 'PDF':
                            query = f"{subject} Unit {unit} {resource_level} notes pdf in Tamil"
                            link = f"https://www.google.com/search?q={urllib.parse.quote_plus(query)}"
                        else: # Visual Explanation
                            query = f"{subject} Unit {unit} {resource_level} diagram explanation Tamil"
                            link = f"https://www.google.com/search?tbm=isch&q={urllib.parse.quote_plus(query)}"
                            
                        # Escape single quotes in subject and title
                        safe_subject = subject.replace("'", "''")
                        safe_title = title.replace("'", "''")
                        
                        sql = f"INSERT INTO learning_resources (subject, unit, risk_level, resource_level, resource_type, title, link, language) " \
                              f"VALUES ('{safe_subject}', {unit}, '{risk_level}', '{resource_level}', '{res_type}', '{safe_title}', '{link}', 'Tamil');\n"
                        f.write(sql)
            f.write("\n")
    print(f"Successfully generated SQL statements in {output_file}")

if __name__ == "__main__":
    generate_resources_sql()
