import re
import json
import os

def parse_syllabus(text_path):
    with open(text_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find Subject Code and Title
    # Pattern: Code (2-3 letters + 4 digits) followed by Title, then L T P C
    subject_pattern = re.compile(r'([A-Z]{2,3}\d{4})\s+(.*?)\s+L\s+T\s+P\s+C', re.DOTALL)
    
    # Regex for Units
    unit_pattern = re.compile(r'UNIT\s+(I|II|III|IV|V)\s+(.*?)(?=UNIT\s+(?:I|II|III|IV|V)|TOTAL\s*:\s*\d+\s*PERIODS|COURSE\s+OUTCOMES|$)', re.DOTALL)

    subjects_dict = {}
    
    # Find all subject matches
    matches = list(subject_pattern.finditer(content))
    
    for i in range(len(matches)):
        match = matches[i]
        code = match.group(1).strip()
        title = match.group(2).strip().replace('\n', ' ')
        
        # Determine the search range for units (from this subject to next subject)
        start_pos = match.end()
        end_pos = matches[i+1].start() if i+1 < len(matches) else len(content)
        subject_text = content[start_pos:end_pos]
        
        units = {}
        unit_matches = unit_pattern.findall(subject_text)
        
        for u_num, u_content in unit_matches:
            # Map Roman numerals to digits
            num_map = {'I': '1', 'II': '2', 'III': '3', 'IV': '4', 'V': '5'}
            clean_content = u_content.strip().replace('\n', ' ')
            # Remove extra spaces
            clean_content = re.sub(r'\s+', ' ', clean_content)
            units[num_map[u_num]] = clean_content
            
        if units:
            subjects_dict[code] = {
                "title": title,
                "units": units
            }
            
    return subjects_dict

if __name__ == "__main__":
    # Correcting paths for execution from backend directory
    input_text = "full_syllabus.txt"
    output_json = "data/r2021_syllabus.json"
    
    # Ensure data directory exists
    os.makedirs("data", exist_ok=True)
    
    if os.path.exists(input_text):
        print(f"Parsing {input_text}...")
        syllabus_data = parse_syllabus(input_text)
        
        with open(output_json, 'w', encoding='utf-8') as f:
            json.dump(syllabus_data, f, indent=2)
            
        print(f"Successfully extracted {len(syllabus_data)} subjects to {output_json}")
        
    else:
        print(f"Error: {input_text} not found. Run extract_all.py first.")
