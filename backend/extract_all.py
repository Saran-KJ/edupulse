import pypdf
import os

def extract_all(pdf_path):
    reader = pypdf.PdfReader(pdf_path)
    text = ""
    for i in range(len(reader.pages)):
        text += reader.pages[i].extract_text() + "\n"
    return text

if __name__ == "__main__":
    pdf_path = r"E:\final-year-project-demo\DOC-20260225-WA0004.pdf"
    content = extract_all(pdf_path)
    with open("full_syllabus.txt", "w", encoding="utf-8") as f:
        f.write(content)
    print("Full extraction successful.")
