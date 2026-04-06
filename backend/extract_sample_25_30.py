import pypdf
import os

def extract_pages(pdf_path, start, end):
    reader = pypdf.PdfReader(pdf_path)
    text = ""
    for i in range(start, min(end, len(reader.pages))):
        text += f"\n--- PAGE {i} ---\n"
        text += reader.pages[i].extract_text() + "\n"
    return text

if __name__ == "__main__":
    pdf_path = r"E:\final-year-project-demo\DOC-20260225-WA0004.pdf"
    content = extract_pages(pdf_path, 25, 30)
    with open("syllabus_sample_25_30.txt", "w", encoding="utf-8") as f:
        f.write(content)
    print("Extraction successful.")
