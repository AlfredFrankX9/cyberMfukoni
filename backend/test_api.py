import urllib.request
import urllib.parse
import json
import random
import sys

# Configure stdout to handle emojis on Windows
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "http://127.0.0.1:8000"

def make_request(path, method="GET", body=None, token=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
        
    data = None
    if body:
        data = json.dumps(body).encode("utf-8")
        
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as res:
            raw_body = res.read().decode("utf-8")
            try:
                return res.status, json.loads(raw_body)
            except Exception as json_err:
                return res.status, {"error": f"JSON decode failed: {json_err}", "raw": raw_body}
    except urllib.error.HTTPError as e:
        raw_body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(raw_body)
        except Exception as json_err:
            return e.code, {"error": f"JSON decode failed on error: {json_err}", "raw": raw_body}
    except Exception as e:
        return 500, {"error": str(e)}

def run_tests():
    # 1. Register a new random user
    username = f"testuser_{random.randint(1000, 9999)}"
    email = f"{username}@example.com"
    password = "TestPassword123!"
    
    print(f"\n--- Testing Register for {username} ---")
    status, res = make_request("/api/auth/register", method="POST", body={
        "username": username,
        "email": email,
        "password": password
    })
    print(f"Status: {status}")
    print(f"Response: {res}")
    if status != 200:
        print("Registration failed!")
        return
        
    token = res.get("access_token")
    
    # 2. Login
    print("\n--- Testing Login ---")
    # Login endpoint uses URL encoded form data
    login_url = f"{BASE_URL}/api/auth/login"
    form_data = urllib.parse.urlencode({"username": username, "password": password}).encode("utf-8")
    req = urllib.request.Request(login_url, data=form_data, headers={"Content-Type": "application/x-www-form-urlencoded"}, method="POST")
    try:
        with urllib.request.urlopen(req) as res_login:
            res_data = json.loads(res_login.read().decode("utf-8"))
            print(f"Status: 200")
            print(f"Response: {res_data}")
            token = res_data.get("access_token")
    except Exception as e:
        print(f"Login failed: {e}")
        return

    # 3. Fetch Intel Feed
    print("\n--- Testing Intel Feed (All) ---")
    status, res = make_request("/api/intel/feed?category=All", token=token)
    print(f"Status: {status}")
    print(f"Items returned: {len(res.get('data', [])) if 'data' in res else 0}")
    if 'data' in res and len(res['data']) > 0:
        print(f"First item: {res['data'][0]['title']}")

    # 4. Analyze message via Mulika
    print("\n--- Testing Mulika Analyze ---")
    status, res = make_request("/api/mulika/analyze", method="POST", token=token, body={
        "message": "Dear customer, your M-PESA account has been suspended due to security issues. Please verify your details immediately at http://mpesa-safari.com/verify",
        "type": "text"
    })
    print(f"Status: {status}")
    print(f"Risk: {res.get('data', {}).get('risk_rating')}")
    print(f"Probability: {res.get('data', {}).get('scam_probability')}%")
    print(f"Explanation: {res.get('data', {}).get('explanation')}")

    # 5. Chat with Agent
    print("\n--- Testing Agent Chat ---")
    status, res = make_request("/api/agent/chat", method="POST", token=token, body={
        "message": "What is SIM swapping and how do I protect my M-Pesa account from it in Kenya?"
    })
    print(f"Status: {status}")
    print(f"Agent Response:\n{res.get('data', {}).get('response')}")

if __name__ == "__main__":
    run_tests()
