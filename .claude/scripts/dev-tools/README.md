# TES Script Development Kit

A comprehensive set of tools for developing, testing, and validating scripts for the Task Execution Service (TES).

## Tools Overview

### 1. Create Script Template (`create-script-template.sh`)

Interactive wizard that helps you create new TES scripts with proper structure and boilerplate code.

**Features:**
- Language selection (Bash, Python, Node.js)
- Category selection with descriptions
- Automatic boilerplate generation with error handling
- Test file generation
- Registry metadata creation

**Usage:**
```bash
./create-script-template.sh
```

The wizard will guide you through:
1. Entering a script name (lowercase, hyphens allowed)
2. Providing a description
3. Selecting the implementation language
4. Choosing a category
5. Defining script arguments

**Output:**
- Main script file with proper structure
- Test file with basic test cases
- Metadata JSON for registry registration

### 2. Test Script Locally (`test-script-locally.sh`)

Run scripts in a sandbox environment that mimics the TES execution environment.

**Features:**
- Resource limit enforcement (memory, CPU)
- Sandbox isolation levels
- Execution time monitoring
- Output validation
- Detailed performance reports

**Usage:**
```bash
# Basic usage
./test-script-locally.sh path/to/script.sh

# With custom timeout (milliseconds)
./test-script-locally.sh --timeout 60000 script.py

# With custom memory limit
./test-script-locally.sh --memory 1GB script.js

# Pass arguments to script
./test-script-locally.sh script.sh -- --input data.json --output result.json

# Verbose mode
./test-script-locally.sh -v script.py
```

**Report includes:**
- Exit code and success status
- Execution time
- Resource usage
- Script output (JSON validated if applicable)
- Error messages

### 3. Validate Metadata (`validate-metadata.py`)

Validate and auto-fix script metadata against the TES registry schema.

**Features:**
- Schema validation
- Type checking
- Auto-fix common issues
- Improvement suggestions
- Batch validation

**Usage:**
```bash
# Validate single metadata file
./validate-metadata.py script-metadata.json

# Auto-fix issues
./validate-metadata.py -f script-metadata.json

# Save fixed metadata
./validate-metadata.py -f -o fixed-metadata.json script-metadata.json

# Validate all scripts in registry
./validate-metadata.py --all

# Show registry schema
./validate-metadata.py --schema
```

**Validation checks:**
- Required fields presence
- Field type correctness
- ID format (category/script-name)
- Version format (semantic versioning)
- Valid categories and permissions
- Security configuration

**Auto-fixes:**
- Generate ID from category and name
- Add 'scripts/' prefix to paths
- Convert string numbers to integers
- Add default version and security config

### 4. Script Linter (`script-linter.py`)

Security and best practices linter for TES scripts.

**Features:**
- Security vulnerability detection
- Best practice validation
- Language-specific checks
- Integration with external tools (shellcheck, bandit)
- Pre-commit hook support

**Usage:**
```bash
# Lint single file
./script-linter.py script.sh

# Lint multiple files
./script-linter.py *.py *.sh

# JSON output
./script-linter.py -j script.py

# Filter by severity
./script-linter.py --severity high script.sh

# Install as pre-commit hook
./script-linter.py --install-hook
```

**Security checks:**
- Hardcoded secrets and credentials
- Command injection vulnerabilities
- Path traversal risks
- Unauthorized network access
- Dangerous system operations

**Best practice checks:**
- Error handling patterns
- Proper variable quoting (shell)
- Code structure and organization
- Modern language features usage
- Resource cleanup

## Quick Start Guide

### Creating a New Script

1. Run the creation wizard:
   ```bash
   ./create-script-template.sh
   ```

2. Edit the generated script to implement your functionality

3. Test locally:
   ```bash
   ./test-script-locally.sh category/script-name.sh
   ```

4. Validate metadata:
   ```bash
   ./validate-metadata.py category/script-name.metadata.json
   ```

5. Run security linter:
   ```bash
   ./script-linter.py category/script-name.sh
   ```

6. Register with TES:
   ```bash
   cd /path/to/scripts
   ./register-script.sh category/script-name.sh
   ```

### Development Workflow

1. **Setup pre-commit hook** (recommended):
   ```bash
   ./script-linter.py --install-hook
   ```

2. **Create new script**:
   ```bash
   ./create-script-template.sh
   ```

3. **Develop iteratively**:
   - Write code
   - Test locally: `./test-script-locally.sh script.py`
   - Fix issues: `./script-linter.py script.py`
   - Validate metadata: `./validate-metadata.py -f metadata.json`

4. **Final validation**:
   ```bash
   # Run all checks
   ./test-script-locally.sh script.py && \
   ./script-linter.py script.py && \
   ./validate-metadata.py metadata.json
   ```

## Best Practices

### Script Development

1. **Always use the template wizard** for new scripts to ensure proper structure
2. **Test early and often** using the local testing tool
3. **Fix linter warnings** before registration
4. **Document your scripts** with clear descriptions and examples

### Security

1. **Never hardcode secrets** - use environment variables
2. **Validate all inputs** before processing
3. **Use minimal permissions** - only request what's needed
4. **Follow sandbox guidelines** - respect resource limits

### Metadata

1. **Keep descriptions concise** but informative (10-200 characters)
2. **Use semantic versioning** (e.g., 1.0.0)
3. **Tag appropriately** for discoverability
4. **Document all arguments** with clear descriptions

## Troubleshooting

### Common Issues

**Script creation fails:**
- Ensure script name follows convention (lowercase, hyphens only)
- Check write permissions in target directory

**Local testing timeout:**
- Increase timeout: `--timeout 60000`
- Check for infinite loops or blocking operations

**Metadata validation errors:**
- Run with auto-fix: `./validate-metadata.py -f`
- Check required fields are present
- Ensure proper JSON formatting

**Linter false positives:**
- Add appropriate permissions in metadata
- Use security annotations in comments
- Consider severity filtering

## Environment Variables

- `TES_DEBUG=1` - Enable debug output in all tools
- `TES_NO_COLOR=1` - Disable colored output
- `TES_SCRIPTS_DIR` - Override default scripts directory

## Requirements

- Bash 4.0+
- Python 3.6+
- Node.js 14+ (for JavaScript scripts)
- jq (for JSON processing)
- Optional: shellcheck, bandit (for enhanced linting)

## Contributing

To add new features or improve existing tools:

1. Follow the existing code style
2. Add comprehensive error handling
3. Include helpful error messages
4. Update this README
5. Test thoroughly before committing

## License

These development tools are part of the TES system and follow the same license terms.