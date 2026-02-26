import re

file_path = r'c:\Users\Hon3y Chauhan\Desktop\BBSYDP-LMS\index.html'

def get_new_questions():
    # Map of 0-based index to new question object string
    return {
        42: '{ q: "Sabse choti heading kaunsi hai?", options: ["h1", "h3", "h6", "mini"], correct: 2 }',
        43: '{ q: "li tag kiske andar use hota hai?", options: ["table", "ul aur ol", "div", "head"], correct: 1 }',
        44: '{ q: "HTML attributes kahan likhe jaate hain?", options: ["Closing tag me", "Opening tag me", "Content me", "Head me"], correct: 1 }',
        45: '{ q: "Kya img tag ka closing tag hota hai?", options: ["Haan", "Nahi", "Kabhi kabhi", "Sirf XHTML me"], correct: 1 }',
        46: '{ q: "Kya tr tag table ke bina use ho sakta hai?", options: ["Haan", "Nahi", "Sirf div me", "CSS ke saath"], correct: 1 }',
        
        55: '{ q: "title tag page par kahan dikhta hai?", options: ["Body me", "Footer me", "Browser Tab me", "URL me"], correct: 2 }',
        56: '{ q: "Website ka Home Page file ka naam kya hona chahiye?", options: ["home.html", "start.html", "main.html", "index.html"], correct: 3 }',
        57: '{ q: "src attribute ka full form kya hai?", options: ["Screen", "Source", "Search", "Script"], correct: 1 }',
        58: '{ q: "href attribute ka full form kya hai?", options: ["Hyper Reference", "Hypertext Reference", "Home Reference", "Head Reference"], correct: 1 }',
        
        77: '{ q: "alt attribute kyun zaroori hai?", options: ["Color ke liye", "Style ke liye", "Screen Readers ke liye", "Speed ke liye"], correct: 2 }',
        
        80: '{ q: "width attribute kis liye use hota hai?", options: ["Chorayi set karne ke liye", "Lambayi set karne ke liye", "Color set karne ke liye", "Border set karne ke liye"], correct: 0 }',
        81: '{ q: "height attribute kis liye use hota hai?", options: ["Chorayi set karne ke liye", "Lambayi set karne ke liye", "Motaai set karne ke liye", "Padding set karne ke liye"], correct: 1 }',
        82: '{ q: "Folder se bahar nikalne ke liye path me kya likhte hain?", options: ["./", "../", "/", "//"], correct: 1 }',
        
        84: '{ q: "Same folder me file link karne ke liye kya likhte hain?", options: ["File ka naam", "/name", "url", "src"], correct: 0 }',
        85: '{ q: "Email link banane ke liye href me kya likhte hain?", options: ["email:", "send:", "mailto:", "to:"], correct: 2 }',
        86: '{ q: "Phone call link banane ke liye href me kya likhte hain?", options: ["call:", "phone:", "tel:", "mob:"], correct: 2 }',
        87: '{ q: "Button banane ke liye kaunsa tag hai?", options: ["<click>", "<btn>", "<button>", "<push>"], correct: 2 }',
        88: '{ q: "Kisi text ko Important dikhane ke liye semantic tag?", options: ["<b>", "<imp>", "<strong>", "<big>"], correct: 2 }',
        
        93: '{ q: "Kisi text ko Emphasized (Tircha) dikhane ke liye semantic tag?", options: ["<i>", "<em>", "<italic>", "<sl>"], correct: 1 }'
    }

def update_file():
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the allQ array content
    # Look for const allQ = [ ... ];
    # Use dotall to capture across lines
    match = re.search(r'(const allQ = \[\s*)(.*?)(\s*\];)', content, re.DOTALL)
    
    if not match:
        print("Could not find allQ array")
        return

    prefix = match.group(1)
    array_body = match.group(2)
    suffix = match.group(3)
    
    # Split the array body into lines/entries
    # We assume each line contains one object or we split by regex for objects
    # The file format seems to have one object per line mostly
    
    # Split by closing brace and comma to separate objects reliably
    # Pattern: { ... },
    
    # Let's try splitting by newlines first as the file seems formatted
    lines = array_body.split('\n')
    
    new_lines = []
    question_idx = 0
    
    replacements = get_new_questions()
    
    for line in lines:
        line_stripped = line.strip()
        if not line_stripped or line_stripped.startswith('//') or line_stripped.startswith('/*'):
            new_lines.append(line)
            continue
            
        # Check if this line is a question object
        if line_stripped.startswith('{') and 'q:' in line_stripped:
            if question_idx in replacements:
                # Preserve indentation
                indent = line[:line.find('{')]
                new_line = indent + replacements[question_idx] + ','
                # Ensure comma is preserved if original had it (it should in array)
                if not line_stripped.endswith(','):
                     new_line = new_line.rstrip(',')
                
                new_lines.append(new_line)
                print(f"Replaced Q{question_idx+1}")
            else:
                new_lines.append(line)
            
            question_idx += 1
        else:
            new_lines.append(line)
            
    # Reconstruct content
    new_array_body = '\n'.join(new_lines)
    new_content = content[:match.start(2)] + new_array_body + content[match.end(2):]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        
    print("File updated successfully.")

if __name__ == "__main__":
    update_file()
