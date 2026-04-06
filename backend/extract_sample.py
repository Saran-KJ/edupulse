import pypdf
import json
import os

def extract_sample(pdf_path, max_pages=20):
    reader = pypdf.PdfReader(pdf_path)
    text = ""
    for i in range(min(max_pages, len(reader.pages))):
        text += f"\n--- PAGE {i+1} ---\n"
        text += reader.pages[i].extract_text() + "\n"
    return text

if __name__ == "__main__":
    pdf_path = r"E:\final-year-project-demo\DOC-20260225-WA0004.pdf"
    content = extract_sample(pdf_path)
    with open("syllabus_sample.txt", "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Sample extraction successful (20 pages).")
