import sys

def inspect(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    for i, l in enumerate(lines):
        stripped = l.strip()
        if stripped.startswith('//') or stripped.startswith('import ') or stripped.startswith('part '):
            continue
        # Look for literal strings enclosed in quotes
        if "'" in stripped or '"' in stripped:
            # check if it looks like user-facing text
            # Ignore imports, asset paths, svg, routes, keys starting with lowercase
            # We want to see if there's any Indonesian text
            for part in stripped.split("'")[1::2]:
                if len(part) > 2 and not part.startswith('assets/') and not '.' in part and any(c.isupper() for c in part):
                    print(f"{file_path}:{i+1}: '{part}'")
            for part in stripped.split('"')[1::2]:
                if len(part) > 2 and not part.startswith('assets/') and not '.' in part and any(c.isupper() for c in part):
                    print(f"{file_path}:{i+1}: \"{part}\"")

if __name__ == '__main__':
    for arg in sys.argv[1:]:
        inspect(arg)
