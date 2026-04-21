def check_braces(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    lines = content.split('\n')
    for i, line in enumerate(lines):
        for char in line:
            if char == '{':
                stack.append(('{', i + 1))
            elif char == '}':
                if not stack:
                    print(f"Extra '}}' at line {i + 1}")
                else:
                    stack.pop()
    
    for brace in stack:
        print(f"Unclosed '{{' opened at line {brace[1]}")

if __name__ == "__main__":
    check_braces(r"c:\Users\Shoxrux\ant\student_platform_frontend\lib\screens\topic_player_screen.dart")
