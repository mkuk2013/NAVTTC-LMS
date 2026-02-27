import re
import json
from collections import defaultdict

with open('c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to find client.from('table').insert({ ... }) or upsert or update
# This is a bit complex for a simple regex, but we can look for basic patterns
# like client.from('table').select('col1, col2')

tables = defaultdict(set)

# Find all .from('table')
table_matches = re.finditer(r"\.from\(['\"]([^'\"]+)['\"]\)(.*?)(?=\.from|\Z)", content, re.DOTALL)

for match in table_matches:
    table_name = match.group(1)
    operations = match.group(2)
    
    # look for selects
    selects = re.findall(r"\.select\(['\"]([^'\"]+)['\"]\)", operations)
    for s in selects:
        cols = [c.strip() for c in s.split(',')]
        for c in cols:
            if c != '*' and c != '':
                tables[table_name].add(c)
                
    # look for eq
    eqs = re.findall(r"\.eq\(['\"]([^'\"]+)['\"]", operations)
    for eq in eqs:
        tables[table_name].add(eq)
        
    # try to find insert/update/upsert payloads
    # This might match the immediate next object
    payloads = re.findall(r"\.(?:insert|update|upsert)\(\s*({[^}]+})\s*\)", operations)
    for p in payloads:
        # extract keys from the JSON-like object
        keys = re.findall(r"['\"]?([a-zA-Z0-9_]+)['\"]?\s*:", p)
        for k in keys:
            tables[table_name].add(k)

# Additional file
try:
    with open('c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/verify.html', 'r', encoding='utf-8') as f:
        content2 = f.read()
    
    table_matches2 = re.finditer(r"\.from\(['\"]([^'\"]+)['\"]\)(.*?)(?=\.from|\Z)", content2, re.DOTALL)
    for match in table_matches2:
        table_name = match.group(1)
        operations = match.group(2)
        selects = re.findall(r"\.select\(['\"]([^'\"]+)['\"]\)", operations)
        for s in selects:
            cols = [c.strip() for c in s.split(',')]
            for c in cols:
                if c != '*' and c != '':
                    tables[table_name].add(c)
        eqs = re.findall(r"\.eq\(['\"]([^'\"]+)['\"]", operations)
        for eq in eqs:
            tables[table_name].add(eq)
except Exception as e:
    pass

for t in tables:
    tables[t] = list(tables[t])

print(json.dumps(tables, indent=2))
