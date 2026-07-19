from duckduckgo_search import DDGS

try:
    results = DDGS().news("cybersecurity threat intelligence vulnerability", max_results=5)
    for r in results:
        print(f"Title: {r.get('title')}")
        print(f"URL: {r.get('url')}")
        print(f"Image: {r.get('image')}")
        print(f"Source: {r.get('source')}")
        print("---")
except Exception as e:
    print(e)
