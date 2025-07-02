# TES Dev Tools - Quick Reference

## 🚀 Quick Commands

### Create New Script
```bash
./create-script-template.sh
```

### Test Script
```bash
./test-script-locally.sh script.py              # Basic test
./test-script-locally.sh script.sh -- arg1 arg2 # With arguments
./test-script-locally.sh --timeout 60000 script # Custom timeout
```

### Validate Metadata
```bash
./validate-metadata.py metadata.json      # Check only
./validate-metadata.py -f metadata.json   # Auto-fix
./validate-metadata.py -f -o fixed.json   # Fix and save
```

### Security Lint
```bash
./script-linter.py script.sh              # Single file
./script-linter.py *.py                   # Multiple files
./script-linter.py --severity high script # High severity only
```

## 📋 Checklists

### Before Committing
- [ ] Script passes local tests
- [ ] No security issues (linter)
- [ ] Metadata validates
- [ ] Tests are passing
- [ ] Documentation updated

### Script Requirements
- [ ] Error handling (set -e for bash)
- [ ] Input validation
- [ ] JSON output format
- [ ] Proper exit codes
- [ ] Resource cleanup

### Metadata Must-Haves
- [ ] Unique ID (category/name)
- [ ] Clear description
- [ ] All arguments documented
- [ ] Security configuration
- [ ] Version number

## 🔍 Common Fixes

### Bash Scripts
```bash
# Add at start of script
set -euo pipefail
trap 'cleanup' EXIT

# Quote variables
"${VAR}" not $VAR

# Use [[ ]] for tests
[[ -f "$file" ]] not [ -f $file ]
```

### Python Scripts
```python
# Add main guard
if __name__ == "__main__":
    main()

# Use logging
import logging
logger = logging.getLogger(__name__)

# Handle errors
try:
    process()
except Exception as e:
    logger.error(f"Failed: {e}")
```

### Node.js Scripts
```javascript
// Use strict mode
'use strict';

// Prefer const/let
const result = await process();

// Handle errors
try {
    await main();
} catch (error) {
    console.error('Error:', error);
    process.exit(1);
}
```

## 🚨 Security Red Flags

### Never Do This
```bash
# Bad: Hardcoded secrets
PASSWORD="secret123"
API_KEY="sk-abc123"

# Bad: Unquoted variables
rm -rf $TEMP_DIR/*

# Bad: eval with user input
eval "$USER_INPUT"
```

### Do This Instead
```bash
# Good: Environment variables
PASSWORD="${TES_PASSWORD:?Password required}"

# Good: Quoted variables
rm -rf "${TEMP_DIR:?}"/*

# Good: Validate input
case "$USER_INPUT" in
    start|stop|status) $USER_INPUT ;;
    *) echo "Invalid command" ;;
esac
```

## 📊 Exit Codes

- `0` - Success
- `1` - General error
- `2` - Misuse of shell command
- `124` - Timeout
- `126` - Command cannot execute
- `127` - Command not found

## 🔧 Debug Mode

```bash
# Enable debug in tools
TES_DEBUG=1 ./test-script-locally.sh script.sh

# Enable debug in scripts
DEBUG=1 ./script.sh

# Bash debug mode
set -x  # Print commands
```

## 📝 Output Format

### Standard TES JSON Output
```json
{
  "status": "success|error",
  "message": "Human readable message",
  "data": {
    // Your data here
  }
}
```

### Error Output
```json
{
  "status": "error",
  "message": "What went wrong",
  "data": null
}
```

## 🏷️ Categories

- `analysis` - Data analysis tools
- `data` - Data transformation
- `validation` - Input validation
- `generation` - Code generation
- `integration` - External services
- `monitoring` - System monitoring
- `core` - Core TES tools

## 🔐 Permissions

- `read_file` - Read local files
- `write_file` - Write local files
- `network` - Network access
- `execute` - Execute commands
- `system` - System operations

## 📚 Resources

- Full docs: `README.md`
- Examples: `example-workflow.sh`
- Registry: `../registry.json`
- Templates: `../templates/`