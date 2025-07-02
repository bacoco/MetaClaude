# Tool Builder - Global Registry Integration

## Overview
This enhancement enables the Tool Builder specialist to automatically register created tools in the MetaClaude Global Script Registry, making them discoverable and reusable by all specialists.

## Integration Points

### 1. Tool Code Generator Enhancement

When the Tool Code Generator creates a new tool, it will:

```yaml
post_generation_steps:
  - validate_tool_output
  - generate_metadata
  - register_in_global_registry
  - notify_specialists
```

### 2. Automatic Registration Process

```javascript
// In Tool Code Generator workflow
async function registerGeneratedTool(toolInfo) {
  const registryEntry = {
    id: generateToolId(toolInfo),
    name: toolInfo.name,
    category: determineCategory(toolInfo.purpose),
    path: toolInfo.outputPath,
    description: toolInfo.description,
    execution: {
      type: getScriptType(toolInfo.language),
      interpreter: getInterpreter(toolInfo.language),
      args: extractArguments(toolInfo.interface),
      timeout: toolInfo.performance.timeout || 30000,
      permissions: determinePermissions(toolInfo.capabilities)
    },
    outputs: extractOutputs(toolInfo.interface),
    specialists: toolInfo.targetSpecialists || [],
    dependencies: toolInfo.dependencies || [],
    version: "1.0.0",
    security: {
      sandbox: determineSandbox(toolInfo.capabilities),
      max_memory: toolInfo.performance.maxMemory || "512MB",
      network_access: toolInfo.capabilities.includes('network')
    },
    tags: generateTags(toolInfo)
  };
  
  // Use the register-script.sh utility
  await executeCommand('register-script.sh', registryEntry);
}
```

### 3. Category Determination

```javascript
function determineCategory(purpose) {
  const categoryMap = {
    'validation': ['validate', 'check', 'verify', 'ensure'],
    'data': ['convert', 'transform', 'process', 'parse'],
    'analysis': ['analyze', 'examine', 'inspect', 'measure'],
    'generation': ['generate', 'create', 'build', 'scaffold'],
    'integration': ['connect', 'integrate', 'sync', 'api'],
    'core': ['utility', 'helper', 'common', 'shared']
  };
  
  for (const [category, keywords] of Object.entries(categoryMap)) {
    if (keywords.some(keyword => purpose.toLowerCase().includes(keyword))) {
      return category;
    }
  }
  
  return 'core'; // Default category
}
```

### 4. Tool Metadata Extraction

```yaml
metadata_extraction:
  from_design_spec:
    - tool_name
    - description
    - purpose
    - target_specialists
    
  from_generated_code:
    - input_parameters
    - output_format
    - dependencies
    - error_handling
    
  from_validation_results:
    - performance_metrics
    - resource_usage
    - security_requirements
```

## Workflow Integration

### Enhanced Tool Creation Workflow

```markdown
# Tool Builder Workflow with Registry Integration

## Phase 1: Requirements Analysis
- step: "Analyze tool requirements"
  agent: "tool-requirements-analyst"
  outputs:
    - purpose
    - target_specialists
    - capabilities

## Phase 2: Design
- step: "Design tool architecture"
  agent: "tool-design-architect"
  outputs:
    - interface_spec
    - performance_requirements
    - security_constraints

## Phase 3: Code Generation
- step: "Generate tool code"
  agent: "tool-code-generator"
  outputs:
    - tool_implementation
    - test_suite
    - documentation

## Phase 4: Validation
- step: "Validate tool"
  agent: "tool-validator"
  outputs:
    - validation_results
    - performance_metrics
    - security_assessment

## Phase 5: Registration (NEW)
- step: "Register in global registry"
  action: use_tool
  tool_id: "core/tool-registrar"
  inputs:
    tool_metadata: "{{ phases.all }}"
    auto_categorize: true
    notify_specialists: true
  outputs_to: "registration_result"

## Phase 6: Distribution
- step: "Distribute to specialists"
  condition: "registration_result.success == true"
  action: notify_specialists
  specialists: "{{ tool_metadata.target_specialists }}"
  message: "New tool available: {{ registration_result.tool_id }}"
```

## Auto-Registration Script

Create a dedicated script for Tool Builder use:

```bash
#!/bin/bash
# .claude/scripts/core/auto-register-tool.sh

# Auto-register tools created by Tool Builder
# This script is called automatically after tool generation

set -euo pipefail

TOOL_PATH="$1"
METADATA_FILE="$2"

# Extract metadata
METADATA=$(cat "$METADATA_FILE")

# Determine script properties
EXTENSION="${TOOL_PATH##*.}"
case "$EXTENSION" in
    py) SCRIPT_TYPE="python_script" ;;
    sh) SCRIPT_TYPE="shell_script" ;;
    js) SCRIPT_TYPE="node_script" ;;
    *) SCRIPT_TYPE="shell_script" ;;
esac

# Parse metadata and register
./register-script.sh \
    --name "$(echo "$METADATA" | jq -r '.name')" \
    --category "$(echo "$METADATA" | jq -r '.category')" \
    --path "$TOOL_PATH" \
    --description "$(echo "$METADATA" | jq -r '.description')" \
    --specialists "$(echo "$METADATA" | jq -r '.specialists | join(",")')" \
    --tags "$(echo "$METADATA" | jq -r '.tags | join(",")')"
```

## Benefits

1. **Automatic Discovery**: All Tool Builder creations are instantly discoverable
2. **Reusability**: Tools become available to all specialists immediately
3. **Standardization**: Consistent metadata and categorization
4. **Version Control**: Automatic versioning of generated tools
5. **Security**: Proper sandboxing based on tool capabilities

## Implementation Steps

1. Update Tool Code Generator to collect metadata
2. Create auto-registration utility
3. Integrate with existing Tool Builder workflow
4. Add notification system for specialists
5. Create feedback loop for tool usage

## Example: Tool Builder Creating a JSON Validator

```yaml
# Tool Requirements
name: "Custom JSON Validator"
purpose: "Validate JSON with custom business rules"
specialists: ["api-ui-designer", "qa-engineer"]

# After generation, automatically registered as:
registry_entry:
  id: "validation/custom-json-validator"
  category: "validation"
  path: "scripts/validation/custom-json-validator.py"
  specialists: ["api-ui-designer", "qa-engineer"]
  tags: ["validation", "json", "custom-rules", "generated"]
```

## Metrics and Monitoring

Track Tool Builder's contribution to the registry:

```javascript
// Registry metrics
{
  total_tools: 45,
  tool_builder_generated: 12,
  most_used_generated_tool: "validation/api-response-validator",
  specialist_adoption: {
    "api-ui-designer": 8,
    "qa-engineer": 6,
    "data-scientist": 4
  }
}
```

---

*Tool Builder Global Registry Integration v1.0*