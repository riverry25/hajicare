import re
import sys
import os

pattern = re.compile(r"""(?:Text\s*\(\s*|title:\s*|subtitle:\s*|label:\s*|hintText:\s*|helperText:\s*|errorText:\s*|SnackBar\s*\([^)]*content:\s*Text\s*\(\s*)['"]([^'"$]{2,})['"]""")

def audit_dir(target_dir):
    for root, dirs, files in os.walk(target_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                findings = []
                for i, line in enumerate(lines):
                    # skip imports or comments
                    stripped = line.strip()
                    if stripped.startswith('//') or stripped.startswith('import ') or stripped.startswith('export '):
                        continue
                    for m in pattern.finditer(line):
                        s = m.group(1).strip()
                        if not s.startswith('assets/') and not s.startswith('http') and not s.startswith('package:') and len(s) > 1:
                            findings.append((i+1, s))
                if findings:
                    print(f"=== {filepath} ({len(findings)} items) ===")
                    for line_num, s in findings[:20]: # show first 20
                        print(f"  L{line_num}: {s}")
                    if len(findings) > 20:
                        print(f"  ... and {len(findings)-20} more")

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else 'lib'
    audit_dir(target)
