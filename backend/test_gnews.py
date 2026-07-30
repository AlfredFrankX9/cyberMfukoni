import os
import httpx

api_key = "47dd12c650f1f10e82ced8c00f76ecdd"
params = {
    "q": "cybersecurity",
    "lang": "en",
    "max": 10,
    "apikey": api_key,
    "sortby": "publishedAt"
}
resp = httpx.get("https://gnews.io/api/v4/search", params=params)
print("Status:", resp.status_code)
if resp.status_code == 200:
    for a in resp.json().get("articles", []):
        print(a["publishedAt"], a["title"])
else:
    print(resp.text)
