import requests
import json

def test_mark_submission():
    # Login
    login_url = "http://localhost:8000/api/auth/login"
    login_data = {"username": "jaya@gmail.com", "password": "Jaya@"}
    
    try:
        session = requests.Session()
        resp = session.post(login_url, data=login_data)
        if resp.status_code != 200:
            print("Login failed")
            return
            
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        
        # Submit Mark
        url = "http://localhost:8000/api/marks/bulk"
        payload = {
            "marks": [
                {
                    "reg_no": "2021CSE001",
                    "student_name": "Rahul Kumar",
                    "dept": "CSE",
                    "year": 2,
                    "section": "A",
                    "semester": 3,
                    "subject_code": "cs3250",
                    "subject_title": "dsa",
                    "university_result_grade": "A+"
                }
            ]
        }
        
        print("Submitting mark with Grade A+...")
        resp = session.post(url, headers=headers, json=payload)
        print(f"Submission Status: {resp.status_code}")
        print(resp.text)
        
        # Verify
        print("Verifying via API...")
        verify_url = "http://localhost:8000/api/marks/class/CSE/2/A?semester=3"
        resp = session.get(verify_url, headers=headers)
        data = resp.json()
        
        for mark in data:
            if mark["reg_no"] == "2021CSE001":
                print(f"Retrieved Grade: {mark.get('university_result_grade')}")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_mark_submission()
