import pypdf
import json
import os

def extract_text(pdf_path):
    reader = pypdf.PdfReader(pdf_path)
    text = ""
    for page in reader.pages:
        text += page.extract_text() + "\n"
    return text

if __name__ == "__main__":
    pdf_path = r"E:\final-year-project-demo\DOC-20260225-WA0004.pdf"
    if os.path.exists(pdf_path):
        content = extract_text(pdf_path)
        with open("extracted_syllabus.txt", "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Extraction successful. First 500 chars: {content[:500]}")
    else:
        print(f"Error: {pdf_path} not found.")
