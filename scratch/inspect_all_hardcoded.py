import os
import re

# Comprehensive scanner
SKIP_FILES = [
    'app_translations.dart',
    'id.dart',
    'en.dart',
    'jv.dart',
    'su.dart',
]

def scan():
    results = {}
    pattern = re.compile(r"""(?:Text\s*\(\s*|title:\s*|subtitle:\s*|label:\s*|hintText:\s*|helperText:\s*|badgeText:\s*|confirmText:\s*|cancelText:\s*|actionLabel:\s*|SnackBar\s*\([^)]*content:\s*Text\s*\(\s*)['"]([^'"$]{2,})['"]""")

    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart') and file not in SKIP_FILES:
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                findings = []
                for i, line in enumerate(lines):
                    stripped = line.strip()
                    if stripped.startswith('//') or stripped.startswith('import ') or stripped.startswith('export ') or stripped.startswith('part '):
                        continue
                    for m in pattern.finditer(line):
                        s = m.group(1).strip()
                        if not s.startswith('assets/') and not s.startswith('http') and not s.startswith('package:') and not s.startswith('/') and len(s) > 1:
                            # skip single symbols or purely punctuation
                            if any(c.isalpha() for c in s):
                                findings.append((i+1, s))
                if findings:
                    results[path] = findings

    total_count = sum(len(v) for v in results.values())
    print(f"TOTAL REMAINING HARDCODED STRINGS FOUND: {total_count} across {len(results)} files.")
    for p, items in results.items():
        print(f"\n=== {p} ({len(items)}) ===")
        for line_num, s in items[:15]:
            print(f"  L{line_num}: {s}")
        if len(items) > 15:
            print(f"  ... and {len(items)-15} more")

if __name__ == '__main__':
    scan()
