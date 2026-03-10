import requests
from bs4 import BeautifulSoup
import json
import re
import time

def scrape_brainkart():
    base_url = "https://www.brainkart.com/menu/anna-university-cse/"
    
    print("Fetching main page...")
    response = requests.get(base_url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    semester_urls = set()
    for a in soup.find_all('a', href=True):
        href = a['href']
        if 'semester--cse' in href.lower() and href.startswith('http'):
            semester_urls.add(href)
            
    print(f"Found {len(semester_urls)} semester URLs.")
    
    subject_urls = set()
    for sem_url in semester_urls:
        print(f"Fetching semester: {sem_url}")
        res = requests.get(sem_url)
        sem_soup = BeautifulSoup(res.text, 'html.parser')
        
        for a in sem_soup.find_all('a', href=True):
            href = a['href']
            # typical subject link: https://www.brainkart.com/materials/computer-networks---cs3591-2060/
            if href.startswith('https://www.brainkart.com/materials/') and 'semester' not in href.lower():
                # Avoid pagination or general links
                if href != 'https://www.brainkart.com/materials/' and 'elective-papers' not in href.lower():
                    # Only add if it likely has a subject code e.g. cs3591
                    if re.search(r'-[a-z]{2,3}\d{3,4}-', href.lower()) or 'materials' in href:
                        subject_urls.add(href)
        time.sleep(1) # polite delay
        
    print(f"Found {len(subject_urls)} subject URLs.")
    
    all_data = []
    
    count = 0
    for subj_url in list(subject_urls)[:]: # Process all
        count += 1
        print(f"Processing {count}/{len(subject_urls)}: {subj_url}")
        res = requests.get(subj_url)
        subj_soup = BeautifulSoup(res.text, 'html.parser')
        
        title_tag = subj_soup.find('h1')
        title = title_tag.text.strip() if title_tag else "Unknown Subject"
        
        # Brainkart might not have content explicitly, we'll use title + url as content
        content_text = f"{title} | Source: {subj_url}"
        
        pdf_links = []
        for a in subj_soup.find_all('a', href=True):
            href = a['href']
            text = a.text.strip()
            if not text:
                continue
                
            is_valid_link = False
            # Check if it's a google drive link, or ends with pdf
            if 'drive.google.com/file/d/' in href or href.lower().endswith('.pdf'):
                is_valid_link = True
            elif 'Download' in text or 'Notes' in text or 'Question' in text:
                if 'http' in href and 'brainkart.com' not in href:
                    is_valid_link = True
                    
            if is_valid_link:
                # Deduplicate links
                if not any(pl['url'] == href for pl in pdf_links):
                    pdf_links.append({"text": text, "url": href})
                    
        if pdf_links:
            all_data.append({
                "title": title,
                "content": content_text,
                "pdf_links": pdf_links,
                "brainkart_url": subj_url
            })
            
        time.sleep(1) # polite delay
        
    print(f"Successfully extracted data for {len(all_data)} subjects.")
    
    with open('brainkart_content.json', 'w', encoding='utf-8') as f:
        json.dump(all_data, f, indent=2, ensure_ascii=False)
        
    print("Done. Saved to brainkart_content.json")

if __name__ == "__main__":
    scrape_brainkart()
