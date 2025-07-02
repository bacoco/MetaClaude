# Script Versioning and Dependency Management

The MetaClaude Script Registry now supports semantic versioning and sophisticated dependency management for all scripts.

## Features

### 1. Semantic Versioning
- Scripts can be versioned using semantic versioning (major.minor.patch)
- Version constraints supported: `^` (compatible), `~` (approximately), `>=`, `>`, `<=`, `<`, `==`
- Backward compatible with non-versioned scripts

### 2. Dependency Management
- **System Dependencies**: External tools and libraries (e.g., `jq`, `git`, `python3`)
- **Package Dependencies**: Language-specific packages (e.g., `pandas`, `faker`)
- **Script Dependencies**: Dependencies on other MetaClaude scripts
- Version constraints for all dependency types

### 3. Version Resolution
- Automatic resolution of "latest" versions
- Support for version ranges and constraints
- Circular dependency detection

### 4. Dependency Installation
- Automatic installation for Python (pip), Node (npm), and system packages
- Virtual environment support for Python packages
- Dependency caching for faster subsequent installs
- Rollback support on failure

## Usage

### Registering a Versioned Script

```bash
# Register a new version with dependencies
./register-script.sh \
  --name "Data Processor" \
  --category data \
  --path "data/processor-v2.py" \
  --version "2.0.0" \
  --changelog "Added CSV support, improved performance by 50%" \
  --dependencies "pandas:^1.3.0,numpy:>=1.20.0" \
  --depends-on "core/validator:^1.0.0" \
  --description "Process and transform data files"
```

### Version Manager CLI

```bash
# List all versions of a script
python3 core/version-manager.py list core/json-validator

# Resolve a version specification
python3 core/version-manager.py resolve "core/json-validator@^2.0.0"

# Check dependency tree
python3 core/version-manager.py deps "data/processor@2.0.0"

# Check for circular dependencies
python3 core/version-manager.py deps "data/processor@2.0.0" --check-circular

# Generate migration guide
python3 core/version-manager.py migrate core/json-validator 1.0.0 2.0.0

# Get installation order
python3 core/version-manager.py install-order "data/processor@2.0.0"
```

### Dependency Installer CLI

```bash
# Install dependencies for a script
python3 core/dependency-installer.py data/processor@2.0.0

# Install without virtual environment
python3 core/dependency-installer.py data/processor@2.0.0 --no-venv

# Install with rollback on failure
python3 core/dependency-installer.py data/processor@2.0.0 --rollback

# Install without cache
python3 core/dependency-installer.py data/processor@2.0.0 --no-cache
```

## Version Constraint Syntax

### NPM-style (recommended)
- `^1.2.3`: Compatible with version (>=1.2.3 <2.0.0)
- `~1.2.3`: Approximately equivalent (>=1.2.3 <1.3.0)
- `1.2.3`: Exact version
- `*` or `latest`: Any version

### Python-style
- `>=1.2.3`: Greater than or equal
- `>1.2.3`: Greater than
- `<=1.2.3`: Less than or equal
- `<1.2.3`: Less than
- `==1.2.3`: Exact match

## Examples

### Example 1: Registering a New Version
```bash
# Register version 2.0.0 of an existing script
./register-script.sh \
  --name "JSON Schema Validator" \
  --category validation \
  --path "validation/json-validator-v2.sh" \
  --version "2.0.0" \
  --changelog "Added support for JSON Schema draft-07, improved error messages" \
  --dependencies "jq:>=1.6,ajv-cli:^5.0.0" \
  --arg "schema:string:true:Schema file path" \
  --arg "data:string:true:Data file path" \
  --arg "verbose:boolean:false:Verbose output"
```

### Example 2: Script with Script Dependencies
```bash
# Register a script that depends on other scripts
./register-script.sh \
  --name "API Test Suite" \
  --category testing \
  --path "testing/api-test-suite.sh" \
  --version "1.0.0" \
  --dependencies "curl:>=7.0.0,jq:>=1.6" \
  --depends-on "core/json-validator:^2.0.0,generation/api-mock:~2.0.0" \
  --description "Comprehensive API testing framework"
```

### Example 3: Checking Breaking Changes
```bash
# Generate a migration guide
python3 core/version-manager.py migrate data/csv-processor 1.5.0 2.0.0
```

Output:
```markdown
# Migration Guide: data/csv-processor
## From v1.5.0 to v2.0.0

### ⚠️ Breaking Changes
- Major version bump from 1 to 2 - expect breaking changes

### Changes

**v2.0.0:**
Changed API to use streams instead of loading entire file into memory
Renamed 'process_file' to 'process_stream'
Added support for gzipped CSV files

### Dependency Changes

**Added:**
- zlib >=1.2.0

**Updated:**
- pandas: ^1.0.0 → ^1.3.0
```

## Best Practices

1. **Version Numbering**
   - Use semantic versioning: MAJOR.MINOR.PATCH
   - Increment MAJOR for breaking changes
   - Increment MINOR for new features (backward compatible)
   - Increment PATCH for bug fixes

2. **Dependencies**
   - Always specify version constraints
   - Use `^` for flexible updates within major version
   - Use `~` for more conservative updates
   - Pin exact versions only when necessary

3. **Changelog**
   - Always provide a changelog entry when registering new versions
   - Be clear about breaking changes
   - List new features and bug fixes

4. **Script Dependencies**
   - Use script dependencies to build modular, reusable components
   - Avoid circular dependencies
   - Keep dependency trees shallow when possible

## Backward Compatibility

The system is fully backward compatible:
- Scripts without versions are treated as version 1.0.0
- Array-style dependencies are converted to object format with `*` (any version)
- Non-versioned script IDs work alongside versioned ones

## Troubleshooting

### "Could not resolve script version"
- Check that the script ID exists: `python3 core/version-manager.py list <script-id>`
- Verify version constraint syntax is correct

### "Circular dependency detected"
- Run `python3 core/version-manager.py deps <script> --check-circular`
- Review and break the circular dependency chain

### "Failed to install dependency"
- Check that the package manager is available
- Verify network connectivity for package downloads
- Try with `--no-venv` flag for system-wide installation
- Use `--rollback` to automatically undo failed installations