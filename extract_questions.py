import re

def extract_questions(file_path, output_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the allQ array
    match = re.search(r'const allQ = \[\s*(.*?)\s*\];', content, re.DOTALL)
    if not match:
        print("Could not find allQ array")
        return

    array_content = match.group(1)
    
    # Updated regex to handle potential single quotes or different spacing
    # { q: "...", options: ["...", ...], correct: N }
    q_pattern = re.compile(r'q:\s*"(.*?)",\s*options:\s*\[(.*?)\],\s*correct:\s*(\d+)')
    
    question_count = 1
    output_lines = []
    
    # Split by lines
    lines = array_content.split('\n')
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('//') or line.startswith('/*'):
            continue
            
        m = q_pattern.search(line)
        if m:
            q_text = m.group(1)
            options_str = m.group(2)
            correct_idx = int(m.group(3))
            
            # Parse options
            opts = [opt.strip('"').strip("'") for opt in re.findall(r'"(.*?)"', options_str)]
            
            output_lines.append(f"Q{question_count}: {q_text}")
            
            letters = ['A', 'B', 'C', 'D']
            for i, opt in enumerate(opts):
                if i < 4:
                    output_lines.append(f"   {letters[i]}) {opt}")
            
            if 0 <= correct_idx < 4:
                output_lines.append(f"   [Correct: {letters[correct_idx]}]")
            
            output_lines.append("") 
            question_count += 1

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(output_lines))
    
    print(f"Extracted {question_count-1} questions to {output_path}")

if __name__ == "__main__":
    extract_questions(
        r'c:\Users\Hon3y Chauhan\Desktop\BBSYDP-LMS\index.html',
        r'c:\Users\Hon3y Chauhan\Desktop\BBSYDP-LMS\exam_questions.txt'
    )
