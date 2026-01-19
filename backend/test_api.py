import urllib.request
import urllib.parse
import json
import ssl

BASE_URL = "http://localhost:8000"

def test_api():
    # 1. Login
    print("Logging in...")
    login_data = urllib.parse.urlencode({
        "username": "admin65@gmail.com",
        "password": "1234678@"
    }).encode()
    
    req = urllib.request.Request(f"{BASE_URL}/api/auth/login", data=login_data, method="POST")
    try:
        with urllib.request.urlopen(req) as response:
            if response.status != 200:
                print(f"Login failed: {response.status}")
                return
            
            data = json.loads(response.read().decode())
            token = data["access_token"]
            print("Login successful. Token received.")
            
            # 2. Get Users
            print("Fetching users...")
            headers = {"Authorization": f"Bearer {token}"}
            req_users = urllib.request.Request(f"{BASE_URL}/api/admin/users", headers=headers, method="GET")
            
            with urllib.request.urlopen(req_users) as response_users:
                if response_users.status == 200:
                    users = json.loads(response_users.read().decode())
                    print(f"Users found: {len(users)}")
                    print(users)
                else:
                    print(f"Get users failed: {response_users.status}")
                    
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code} - {e.read().decode()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_api()
