import requests
from bs4 import BeautifulSoup
import json
import time

BASE_URL = "https://cse.poriyaan.in/"

def get_subject_links():
    print("Fetching main page...")
    response = requests.get(BASE_URL)
    soup = BeautifulSoup(response.content, 'html.parser')
    
    links = []
    # Find all links that look like subject pages
    for a in soup.find_all('a', href=True):
        href = a['href']
        if 'paper/' in href and 'poriyaan.in' in href:
            links.append((a.text.strip(), href))
            
    print(f"Found {len(links)} subject links.")
    return links

def scrape_subject(url):
    print(f"Scraping {url} ...")
    try:
        response = requests.get(url, timeout=10)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract title
        title_tag = soup.find('h1')
        title = title_tag.text.strip() if title_tag else ""
        
        # Extract content blocks (headers and paragraphs)
        content_blocks = []
        for element in soup.find_all(['h2', 'h3', 'p', 'ul']):
            text = element.get_text(strip=True)
            if text:
                content_blocks.append(text)
                
        # Extract PDF links
        pdf_links = []
        for a in soup.find_all('a', href=True):
            if 'drive.google.com' in a['href'] or '.pdf' in a['href'] or 'document' in a['href'].lower():
                pdf_links.append({"text": a.text.strip(), "url": a['href']})

        return {
            "url": url,
            "title": title,
            "content": "\n".join(content_blocks),
            "pdf_links": pdf_links
        }
    except Exception as e:
        print(f"Error scraping {url}: {e}")
        return None

def main():
    links = get_subject_links()
    
    # We will scrape all unique links
    unique_links = list({url for title, url in links})
    
    all_data = []
    
    for url in unique_links:
        data = scrape_subject(url)
        if data:
            all_data.append(data)
        time.sleep(1) # Be polite
        
    output_file = "poriyaan_content.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully scraped {len(all_data)} subjects and saved to {output_file}")

if __name__ == "__main__":
    main()
