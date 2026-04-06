import re
import requests
from database import SessionLocal
from models import LearningResource

def get_drive_links(url):
    try:
        r = requests.get(url, timeout=10)
        # Regex to find direct href urls for drive.google.com within HTML
        # Group 1: The title (text of the link)
        # Group 2: The actual Drive URL
        # Pattern: <a...href="(https://drive.google.com/[^"]+)"[^>]*>(.*?)</a>
        links = re.findall(r'href="(https://drive\.google\.com/[^"]+)"[^>]*>(.*?)</a>', r.text, re.DOTALL)
        
        # Also handle cases where title is outside the <a> tag or in a list
        # We'll normalize these in the main loop
        return links
    except:
        return []

def scrape_poriyaan():
    db = SessionLocal()
    
    subject_pages = [
        ('HS3151', 'https://www.poriyaan.in/paper/professional-english-i-1/'),
        ('MA3151', 'https://www.poriyaan.in/paper/matrices-and-calculus-2/'),
        ('PH3151', 'https://www.poriyaan.in/paper/engineering-physics-3/'),
        ('CY3151', 'https://www.poriyaan.in/paper/engineering-chemistry-4/'),
        ('GE3151', 'https://www.poriyaan.in/paper/problem-solving-and-python-programming-5/'),
        ('HS3251', 'https://www.poriyaan.in/paper/professional-english-ii-7/'),
        ('MA3251', 'https://www.poriyaan.in/paper/statistics-and-numerical-methods-8/'),
        ('GE3251', 'https://www.poriyaan.in/paper/engineering-graphics-9/'),
        ('PH3256', 'https://www.poriyaan.in/paper/physics-for-information-science-20/'),
        ('BE3251', 'https://www.poriyaan.in/paper/basic-electrical-and-electronics-engineering-21/'),
        ('CS3251', 'https://www.poriyaan.in/paper/programming-in-c-22/'),
        ('MA3354', 'https://www.poriyaan.in/paper/discrete-mathematics-72/'),
        ('CS3351', 'https://www.poriyaan.in/paper/digital-principles-and-computer-organization-73/'),
        ('CS3352', 'https://www.poriyaan.in/paper/foundation-of-data-science-74/'),
        ('CS3301', 'https://www.poriyaan.in/paper/data-structure-75/'),
        ('CS3391', 'https://www.poriyaan.in/paper/object-oriented-programming-76/'),
        ('CS3452', 'https://www.poriyaan.in/paper/theory-of-computation-77/'),
        ('CS3491', 'https://www.poriyaan.in/paper/artificial-intelligence-and-machine-learning-78/'),
        ('CS3492', 'https://www.poriyaan.in/paper/database-management-system-79/'),
        ('CS3401', 'https://www.poriyaan.in/paper/algorithms-80/'),
        ('CS3451', 'https://www.poriyaan.in/paper/introduction-to-operating-systems-81/'),
        ('CS3591', 'https://www.poriyaan.in/paper/computer-networks-82/'),
        ('CS3501', 'https://www.poriyaan.in/paper/compiler-design-83/'),
        ('CB3491', 'https://www.poriyaan.in/paper/cryptography-and-cyber-security-84/'),
        ('CS3551', 'https://www.poriyaan.in/paper/distributed-computing-85/'),
        ('CCS356', 'https://www.poriyaan.in/paper/object-oriented-software-engineering-86/'),
        ('CS3691', 'https://www.poriyaan.in/paper/embedded-systems-and-iot-87/')
    ]
    
    try:
        print(f"🚀 Starting Final Master Scrape for {len(subject_pages)} subjects...")
        total_added = 0
        
        for code, url in subject_pages:
            print(f"Crawling {code}...")
            links = get_drive_links(url)
            
            new_resources = []
            for drive_url, raw_title in links:
                # Clean HTML tags from title
                title = re.sub('<[^<]+?>', '', raw_title).strip()
                if not title: title = f"{code} Learning Resource"
                
                # Cleanup Drive URL
                if "usp=drive_link" in drive_url:
                    drive_url = drive_url.split("?")[0]
                
                # Determine unit info
                unit_match = re.search(r'Unit\s*(\d+)', title, re.I)
                unit = unit_match.group(1) if unit_match else "1"
                
                res = LearningResource(
                    subject_code=code,
                    title=f"{code}: {title}",
                    url=drive_url,
                    type='pdf',
                    unit=unit,
                    min_risk_level='Low',
                    resource_level='Advanced',
                    language='English'
                )
                new_resources.append(res)
            
            if new_resources:
                db.add_all(new_resources)
                db.commit()
                total_added += len(new_resources)
                print(f" ✨ Added {len(new_resources)} Drive links for {code}.")
            
        print(f"\n🎉 MASTER SCRAPE COMPLETE: Total {total_added} direct Drive PDFs added!")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    scrape_poriyaan()
