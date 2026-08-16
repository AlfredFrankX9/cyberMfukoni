import re
from collections import Counter
with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()
keys = re.findall(r"^\s*'([^']+)'\s*:\s*\{", content, re.MULTILINE)
counts = Counter(keys)
dupes = [k for k, v in counts.items() if v > 1]
print('Duplicates:', dupes)
