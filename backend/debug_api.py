import requests
import json

def test_api():
    # Login first to get token
    login_url = "http://localhost:8000/api/auth/login"
    login_data = {
        "username": "jaya@gmail.com",
        "password": "Jaya@"
    }
    
    try:
        session = requests.Session()
        response = session.post(login_url, data=login_data)
        
        if response.status_code != 200:
            print(f"Login failed: {response.status_code} {response.text}")
            return
            
        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # Call the failing endpoint
        url = "http://localhost:8000/api/marks/class/CSE/2/A?semester=3"
        response = session.get(url, headers=headers)
        
        print(f"Status: {response.status_code}")
        if response.status_code == 422:
            print("Validation Error Details:")
            print(json.dumps(response.json(), indent=2))
        else:
            print(response.text)
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_api()
