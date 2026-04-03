import re

with open('DESCRIPTION', 'r') as f:
    content = f.read()

# Find the Collate block
match = re.search(r'(Collate:\s*\n)(.*)', content, re.DOTALL)
if match:
    prefix = match.group(1)
    files = match.group(2)
    # Check if 'init_duckdb.R' is already in files
    if 'init_duckdb.R' not in files:
        # Add it to the top of the list for simplicity, or bottom
        files_lines = files.split('\n')
        # Insert it before the first element
        files_lines.insert(0, "    'init_duckdb.R'")
        new_files = '\n'.join(files_lines)
        new_content = content[:match.start()] + prefix + new_files
        with open('DESCRIPTION', 'w') as f:
            f.write(new_content)
        print("Patched DESCRIPTION")
    else:
        print("Already patched")
