# Migration Guide: Optimizing Agent Files

## Overview
This guide explains how to migrate existing monolithic agent files to the optimized structure that separates core prompts from implementations.

## Current Structure (Before)
```
agents/
  frontend-team/
    table-builder.md (1,791 lines - contains everything)
```

## Optimized Structure (After)
```
agents/
  frontend-team/
    table-builder/
      core.md              (100 lines - essential prompt)
      summary.md           (10 lines - quick description)
      implementations/
        react-typescript.md
        vue-javascript.md
        angular.md
      patterns.md          (common patterns)
      examples.md          (usage examples)
```

## Migration Steps

### Step 1: Analyze Current Agent File

```bash
# Check file size
wc -l agents/frontend-team/table-builder.md
# Output: 1791 lines

# Identify sections
grep -n "^##" agents/frontend-team/table-builder.md
```

### Step 2: Extract Core Prompt

Create `core.md` with only essential elements:

```markdown
# [Agent Name] - Core Prompt

## Role
[1-2 sentences describing the agent's primary responsibility]

## Core Purpose
[Brief description of what the agent generates]

## Input Requirements
```yaml
required:
  - [key inputs needed]
optional:
  - [optional parameters]
```

## Generation Process
[4-5 step high-level process]

## Output Format
[Brief description of expected output structure]

## Quality Standards
[Key quality requirements]

## Integration Points
[How it works with other agents]
```

### Step 3: Create Summary File

Create `summary.md` with ultra-concise information:

```markdown
# [Agent Name] - Summary

**Purpose**: [One line description]
**Inputs**: [Key inputs]
**Outputs**: [What it produces]
**Dependencies**: [Required agents/data]
**Context Size**: Core: [X] lines, Full: [Y] lines
**Priority**: [High/Medium/Low]
**Capabilities**: [Key features]
```

### Step 4: Move Implementations

Extract all code examples to separate files:

```javascript
// implementations/react-typescript.md
// Full TypeScript/React implementations

// implementations/vue-javascript.md  
// Vue.js implementations

// patterns.md
// Common patterns that apply across frameworks
```

### Step 5: Update Agent Registry

Add metadata to the agent registry:

```javascript
// orchestrator/agent-registry.js
export const AGENT_REGISTRY = {
  'frontend-team': {
    'table-builder': {
      coreSize: 100,
      fullSize: 1791,
      implementations: ['react-typescript', 'vue-javascript', 'angular'],
      priority: 'high',
      dependencies: ['schema', 'api-endpoints'],
      path: 'agents/frontend-team/table-builder'
    }
  }
};
```

## Example Migration: Table Builder

### Before (Monolithic)
```markdown
# Table Builder Agent

## Purpose
Generates feature-rich, responsive data tables...

## Capabilities
[Detailed 40-line capability list]

## Table Generation Strategy
[300 lines of TypeScript implementation]

## Column Generation Implementation
[200 lines of code]

## React Component Examples
[500 lines of React code]

## Vue Component Examples
[400 lines of Vue code]

[... continues for 1,791 lines total]
```

### After (Optimized)

#### core.md (100 lines)
```markdown
# Table Builder Agent - Core Prompt

## Role
You are the Table Builder Agent, responsible for generating feature-rich data tables.

## Core Purpose
Generate production-ready table components with sorting, filtering, and pagination.

## Input Requirements
```yaml
required:
  - entity_schema
  - ui_framework
  - data_size
```

## Generation Process
1. Analyze entity structure
2. Select table features based on data size
3. Generate table configuration
4. Create component code

## Output Format
Framework-specific table component with full functionality

## Quality Standards
- WCAG AA accessibility
- Mobile-responsive
- Optimized performance
```

#### summary.md (10 lines)
```markdown
# Table Builder Agent - Summary

**Purpose**: Generates data tables with sorting, filtering, pagination
**Inputs**: Entity schema, UI framework, data size
**Outputs**: Table components with full CRUD functionality
**Dependencies**: API endpoints, theme system
**Context Size**: Core: 100 lines, Full: 1,791 lines
**Priority**: High
**Capabilities**: Virtual scrolling, bulk operations, inline editing
```

## Automation Script

```bash
#!/bin/bash
# migrate-agent.sh - Automate agent migration

AGENT_PATH=$1
AGENT_NAME=$(basename $AGENT_PATH .md)
TEAM=$(basename $(dirname $AGENT_PATH))

# Create directory structure
mkdir -p "agents/$TEAM/$AGENT_NAME/implementations"

# Extract sections (example with common patterns)
awk '/^## Role/,/^## Core Purpose/' $AGENT_PATH > "agents/$TEAM/$AGENT_NAME/core.md"
awk '/^## Purpose/,/^## Capabilities/' $AGENT_PATH > "agents/$TEAM/$AGENT_NAME/summary.md"

# Extract implementations by language
awk '/```typescript/,/```/' $AGENT_PATH > "agents/$TEAM/$AGENT_NAME/implementations/typescript.md"
awk '/```javascript/,/```/' $AGENT_PATH > "agents/$TEAM/$AGENT_NAME/implementations/javascript.md"

echo "Migrated $AGENT_NAME"
echo "Original size: $(wc -l < $AGENT_PATH) lines"
echo "Core size: $(wc -l < agents/$TEAM/$AGENT_NAME/core.md) lines"
```

## Validation Checklist

After migration, verify:

- [ ] Core prompt is under 150 lines
- [ ] Summary is exactly 10 lines
- [ ] All code moved to implementations/
- [ ] Agent still functions correctly
- [ ] Context usage reduced by 80%+
- [ ] Loading time improved
- [ ] No functionality lost

## Benefits After Migration

1. **Context Efficiency**: 90% reduction in context usage
2. **Faster Loading**: Load only what's needed
3. **Better Organization**: Clear separation of concerns
4. **Easier Maintenance**: Update implementations without touching prompts
5. **Flexible Loading**: Choose implementation based on user's framework

---

*Migration Guide v1.0 | Transform monolithic agents into optimized modules*