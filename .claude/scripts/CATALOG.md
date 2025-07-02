# MetaClaude Global Script Registry - Catalog

## Overview
This catalog documents all available scripts in the MetaClaude Global Script Registry. Scripts are organized by category and can be used by any MetaClaude specialist through the Tool Execution Service (TES).

## Quick Start

### Search for Scripts
```bash
# Find all validation scripts
./search-scripts.sh --category validation

# Find scripts for a specific specialist
./search-scripts.sh --specialist qa-engineer

# Search by tags
./search-scripts.sh --tags json,validation --details
```

### Execute a Script
```bash
# Execute through TES with security sandboxing
./execute-tool.sh validation/json-schema-validator \
  --arg schema_path=./schema.json \
  --arg data_path=./data.json

# Get JSON output for integration
./execute-tool.sh data/csv-to-json \
  --arg input_file=data.csv \
  --json
```

### Register New Scripts
```bash
# Register a new validation script
./register-script.sh \
  --name "XML Validator" \
  --category validation \
  --path "validation/xml-validator.sh" \
  --description "Validates XML files against XSD schemas" \
  --specialists "api-ui-designer,data-scientist"
```

## Available Scripts by Category

### 🛡️ Validation Scripts

#### JSON Schema Validator
- **ID**: `validation/json-schema-validator`
- **Purpose**: Validates JSON files against a JSON schema
- **Specialists**: api-ui-designer, data-scientist, prd-specialist
- **Usage**:
  ```bash
  ./execute-tool.sh validation/json-schema-validator \
    --arg schema_path=./api-schema.json \
    --arg data_path=./response.json
  ```
- **Outputs**: 
  - `is_valid`: Boolean indicating validation success
  - `errors`: Array of validation errors

### 📊 Data Processing Scripts

#### JSON to CSV Converter
- **ID**: `data/json-to-csv`
- **Purpose**: Convert JSON arrays to CSV format with automatic header detection
- **Specialists**: data-scientist, api-ui-designer, database-admin-builder
- **Usage**:
  ```bash
  # Output to file
  ./execute-tool.sh data/json-to-csv \
    --arg input_file=users.json \
    --arg output_file=users.csv
  
  # Output to stdout
  ./execute-tool.sh data/json-to-csv \
    --arg input_file=data.json
  ```
- **Outputs**:
  - `json_data`: Output file information
  - `row_count`: Number of rows converted

#### CSV to JSON Converter
- **ID**: `data/csv-to-json`
- **Purpose**: Convert CSV files to JSON format with type inference
- **Specialists**: data-scientist, database-admin-builder
- **Note**: Example placeholder - implement based on json-to-csv pattern

#### YAML to JSON Converter
- **ID**: `data/yaml-to-json`
- **Purpose**: Convert YAML files to JSON format with validation
- **Specialists**: devops-engineer, api-ui-designer, code-architect
- **Usage**:
  ```bash
  # Pretty print JSON
  ./execute-tool.sh data/yaml-to-json \
    --arg input_file=config.yaml \
    --arg output_file=config.json
  
  # Compact JSON
  ./execute-tool.sh data/yaml-to-json \
    --arg input_file=config.yaml \
    --arg compact=true
  ```
- **Outputs**:
  - `json_data`: Output file information
  - `data_type`: Type of root data structure
  - `size`: Size of JSON output

### 🔧 Core Utilities

#### Git Operations Helper
- **ID**: `core/git-operations`
- **Purpose**: Common git operations for MetaClaude specialists
- **Specialists**: code-architect, devops-engineer, qa-engineer, ui-designer
- **Operations**:
  - `check-status`: Check repository status
  - `create-branch`: Create and checkout new branch
  - `safe-commit`: Commit with pre-checks
  - `push-branch`: Push with upstream tracking
  - `check-conflicts`: Check for merge conflicts
  - `stash-changes`: Stash current changes
- **Usage**:
  ```bash
  # Check status
  ./execute-tool.sh core/git-operations \
    --arg operation=check-status
  
  # Create feature branch
  ./execute-tool.sh core/git-operations \
    --arg operation=create-branch \
    --arg branch=feature/new-ui
  
  # Safe commit
  ./execute-tool.sh core/git-operations \
    --arg operation=safe-commit \
    --arg message="Add validation logic"
  ```

#### Auto-Register Tool
- **ID**: `core/auto-register-tool`
- **Purpose**: Automatically register Tool Builder generated tools
- **Internal Use**: Called by Tool Builder specialist
- **Usage**:
  ```bash
  ./auto-register-tool.sh ./generated-tool.sh ./tool-metadata.json
  ```

### 📈 Analysis Scripts

#### Code Complexity Analyzer
- **ID**: `analysis/code-complexity`
- **Purpose**: Analyze code complexity metrics (cyclomatic, cognitive)
- **Specialists**: code-architect, qa-engineer, critic-analyst
- **Note**: Example placeholder - requires implementation with radon/lizard

### 🎯 Generation Scripts

#### API Mock Data Generator
- **ID**: `generation/api-mock`
- **Purpose**: Generate realistic mock data for API endpoints
- **Specialists**: api-ui-designer, qa-engineer, test-case-generator
- **Note**: Example placeholder - requires faker/json-schema-faker

### 🔌 Integration Scripts

#### GitHub PR Automation
- **ID**: `integration/github-pr`
- **Purpose**: Create and manage GitHub pull requests
- **Specialists**: devops-engineer, code-architect
- **Note**: Example placeholder - requires gh CLI

## Security Model

### Sandbox Levels
Scripts run in different security sandboxes based on their requirements:

1. **minimal** (Most Restrictive)
   - Read-only file access
   - No network access
   - Limited memory (512MB default)
   - Used for: validation, simple conversions

2. **standard** (Balanced)
   - Read/write file access with restrictions
   - No network access
   - Moderate memory limits
   - Used for: data processing, git operations

3. **strict** (Read-Only)
   - Read-only file access
   - Minimal environment
   - No external dependencies
   - Used for: analysis, inspection

4. **network** (Network Enabled)
   - File and network access
   - Allowed hosts whitelist
   - Environment variables access
   - Used for: API integrations

## Usage in Agent Workflows

### Example: Data Processing Pipeline
```markdown
# In any specialist workflow
- step: "Convert configuration to JSON"
  action: use_tool
  tool_id: "data/yaml-to-json"
  inputs:
    input_file: "./config/app.yaml"
    output_file: "./config/app.json"
  outputs_to: "config_conversion"

- step: "Validate configuration"
  action: use_tool
  tool_id: "validation/json-schema-validator"
  inputs:
    schema_path: "./schemas/config.schema.json"
    data_path: "./config/app.json"
  outputs_to: "validation_result"

- step: "Process if valid"
  condition: "validation_result.is_valid == true"
  action: continue_workflow
```

## Contributing New Scripts

### 1. Create the Script
Place your script in the appropriate category directory:
- `validation/` - Validators and checkers
- `data/` - Data processing and transformation
- `analysis/` - Code and data analysis
- `generation/` - Content generators
- `integration/` - External service integrations
- `core/` - Essential utilities

### 2. Register the Script
```bash
./register-script.sh \
  --name "Your Script Name" \
  --category category_name \
  --path "category/script-name.sh" \
  --description "What it does" \
  --specialists "specialist1,specialist2" \
  --arg "param1:string:true:Description" \
  --output "result:object:Output description"
```

### 3. Add Examples
Create example usage in `examples/your-script-example.md`

### 4. Test with TES
```bash
./execute-tool.sh category/your-script --dry-run
```

## Best Practices

1. **Use Appropriate Sandbox**: Request minimal permissions needed
2. **Handle Errors Gracefully**: Return structured error information
3. **Document Thoroughly**: Include examples and edge cases
4. **Version Carefully**: Use semantic versioning
5. **Test Extensively**: Validate with different inputs
6. **Consider Performance**: Set appropriate timeouts and memory limits

## Troubleshooting

### Script Not Found
```bash
# Verify script is registered
./search-scripts.sh --name "script-name"

# Check registry directly
jq '.scripts[] | select(.name == "Script Name")' registry.json
```

### Permission Denied
- Check sandbox level in registry
- Verify required permissions are declared
- Ensure file paths are accessible

### Timeout Issues
- Increase timeout in registry if needed
- Optimize script performance
- Consider breaking into smaller operations

## Future Enhancements

- [ ] Script versioning and rollback
- [ ] Usage analytics and metrics
- [ ] Dependency auto-installation
- [ ] Script composition and chaining
- [ ] Visual script browser
- [ ] Performance benchmarking

---

*MetaClaude Global Script Registry Catalog v1.0*