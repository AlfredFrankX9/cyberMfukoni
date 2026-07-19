import httpx

r = httpx.get("http://127.0.0.1:8000/api/intel/feed")
d = r.json()
print(f"Status: {d['status']}, Count: {len(d['data'])}")
for a in d['data'][:5]:
    print(f"  [{a['threat_level']}] {a['title'][:70]}")
    print(f"     image: {a.get('image_url', 'NONE')[:60]}")
    print(f"     url:   {a.get('url', 'NONE')[:60]}")
