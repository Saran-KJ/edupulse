import requests

def test():
    session = requests.Session()
    login_data = {"username": "jaya@gmail.com", "password": "Jaya@"}
    r = session.post("http://localhost:8000/api/auth/login", data=login_data)
    if r.status_code != 200:
        print("Login failed")
        return
    token = r.json()["access_token"]
    
    r2 = session.get("http://localhost:8000/api/marks/student/2021CSE003", headers={"Authorization": f"Bearer {token}"})
    if r2.status_code == 200:
        marks = r2.json()
        print(f"Found {len(marks)} marks.")
        for m in marks:
            print(f"Subject: {m.get('subject_code')}, Grade: '{m.get('university_result_grade')}'")
    else:
        print("Failed to get marks")

if __name__ == "__main__":
    test()
