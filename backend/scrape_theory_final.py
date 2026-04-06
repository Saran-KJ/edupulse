import re
import requests
from database import SessionLocal
from models import LearningResource

def get_drive_links(url):
    try:
        r = requests.get(url, timeout=10)
        # Regex to find direct href urls for drive.google.com within HTML
        links = re.findall(r'href="(https://drive\.google\.com/[^"]+)"[^>]*>(.*?)</a>', r.text, re.DOTALL)
        return links
    except:
        return []

def scrape_missing_theory():
    db = SessionLocal()
    
    # Targeting the missing core and common theory subjects
    subject_pages = [
        ('GE3451', 'https://www.poriyaan.in/paper/environmental-sciences-and-sustainability-29/'),
        ('GE3791', 'https://www.poriyaan.in/paper/human-values-and-ethics-88/'),
        # Mapping HS3152/HS3252 to their regulation counterparts HS3151/HS3251
        ('HS3152', 'https://www.poriyaan.in/paper/professional-english-i-1/'),
        ('HS3252', 'https://www.poriyaan.in/paper/professional-english-ii-7/'),
        # Adding common electives
        ('CCS356', 'https://www.poriyaan.in/paper/object-oriented-software-engineering-86/'),
        ('CS3691', 'https://www.poriyaan.in/paper/embedded-systems-and-iot-87/')
    ]
    
    try:
        print(f"🚀 Finalizing Theory Coverage for {len(subject_pages)} critical subjects...")
        total_added = 0
        
        for code, url in subject_pages:
            print(f"Crawling {code}...")
            links = get_drive_links(url)
            
            new_resources = []
            for drive_url, raw_title in links:
                title = re.sub('<[^<]+?>', '', raw_title).strip()
                if not title: title = f"{code} Learning Resource"
                if "usp=drive_link" in drive_url: drive_url = drive_url.split("?")[0]
                
                # Check for unit
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
                print(f" ✨ Added {len(new_resources)} direct Drive links for {code}.")
            
        print(f"\n🎉 FINAL SYNC COMPLETE: Total {total_added} direct Drive PDFs added!")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    scrape_missing_theory()
