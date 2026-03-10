import requests
from bs4 import BeautifulSoup
import json

def test():
    url = "https://www.brainkart.com/materials/computer-networks---cs3591-2060/"
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    links = []
    # Sometimes it's lists of topics or units
    for a in soup.find_all('a', href=True):
        if 'javascript' not in a['href'] and '#' not in a['href']:
            links.append((a.text.strip(), a['href']))
            
    num_links = len(links)
    print(json.dumps(links[10:50], indent=2))
    print("Total links:", num_links)

if __name__ == "__main__":
    test()
