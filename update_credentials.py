import os
import re

files_to_update = [
    r"c:\Users\Hon3y Chauhan\Desktop\NAVTTC-LMS\index.html",
    r"c:\Users\Hon3y Chauhan\Desktop\NAVTTC-LMS\verify.html",
    r"c:\Users\Hon3y Chauhan\Desktop\NAVTTC-LMS\feedback.html",
    r"c:\Users\Hon3y Chauhan\Desktop\NAVTTC-LMS\feedback_details.html"
]

NEW_URL = "https://fnkctvhrilynnmphdxuo.supabase.co"
NEW_KEY = "sb_publishable_q_jbUM95dckWS7YF1XSRgg_NvhZ4iyU"

for file_path in files_to_update:
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        content = re.sub(r'const\s+SUPABASE_URL\s*=\s*["\'][^"\']+["\'];?', f'const SUPABASE_URL = "{NEW_URL}";', content)
        content = re.sub(r'const\s+SUPABASE_ANON_KEY\s*=\s*["\'][^"\']+["\'];?', f'const SUPABASE_ANON_KEY = "{NEW_KEY}";', content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {file_path}")
    else:
        print(f"File not found: {file_path}")
