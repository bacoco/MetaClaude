# Tool Usage Matrix Pattern

Comprehensive mapping of UI Designer Claude's conceptual operations to Claude Code's concrete tools.

## Overview

This matrix provides explicit guidance on when and how to use Claude Code's tools (`read_file`, `write_file`, `run_shell_command`, etc.) versus performing internal reasoning and generation.

## Core Tools Available

1. **read_file**: Read existing files for analysis or reference
2. **write_file**: Create or overwrite files with generated content
3. **run_shell_command**: Execute bash commands (npm, git, etc.)
4. **search_file_content**: Search for patterns in files
5. **list_files**: List directory contents

## Master Tool Usage Matrix

| Operation | Description | Tool to Use | Example Usage |
|-----------|-------------|-------------|---------------|
| Analyze existing design | Review current UI code | `read_file` | `read_file("src/components/Dashboard.jsx")` |
| Extract project structure | Understand file organization | `list_files` | `list_files("src/")` |
| Save generated component | Store new UI component | `write_file` | `write_file("Button.jsx", componentCode)` |
| Create design tokens | Save design system JSON | `write_file` | `write_file("tokens.json", tokenData)` |
| Search for patterns | Find existing components | `search_file_content` | `search_file_content("className=", "src/")` |
| Install dependencies | Add design packages | `run_shell_command` | `run_shell_command("npm install tailwindcss")` |
| Build project | Compile and check | `run_shell_command` | `run_shell_command("npm run build")` |
| Initialize config | Create config files | `write_file` | `write_file("tailwind.config.js", config)` |
| Check current state | Verify changes | `run_shell_command` | `run_shell_command("git status")` |
| Analyze images | View inspiration files | `read_file` | `read_file("inspiration/design.png")` |

## Specialist-Specific Tool Usage

### Design Analyst

| Task | Internal Only | Requires Tool | Tool & Usage |
|------|--------------|---------------|--------------|
| Extract visual DNA | ✓ | ✗ | Describe patterns internally |
| Analyze inspiration image | ✗ | ✓ | `read_file("path/to/image.png")` |
| Document findings | ✗ | ✓ | `write_file("analysis.md", report)` |
| Compare designs | ✓ | ✗ | Internal comparison |

### UI Generator

| Task | Internal Only | Requires Tool | Tool & Usage |
|------|--------------|---------------|--------------|
| Generate component code | ✓ | ✗ | Create in response |
| Save component to file | ✗ | ✓ | `write_file("Component.jsx", code)` |
| Check existing components | ✗ | ✓ | `read_file("src/components/")` |
| Create multiple files | ✗ | ✓ | Multiple `write_file` calls |

### Style Guide Expert

| Task | Internal Only | Requires Tool | Tool & Usage |
|------|--------------|---------------|--------------|
| Generate design tokens | ✓ | ✗ | Create JSON internally |
| Save token file | ✗ | ✓ | `write_file("design-tokens.json", tokens)` |
| Create CSS variables | ✓ | ✗ | Generate in response |
| Export Tailwind config | ✗ | ✓ | `write_file("tailwind.config.js", config)` |

### UX Researcher

| Task | Internal Only | Requires Tool | Tool & Usage |
|------|--------------|---------------|--------------|
| Create user personas | ✓ | ✗ | Generate documentation |
| Analyze existing docs | ✗ | ✓ | `read_file("docs/user-research.md")` |
| Save research findings | ✗ | ✓ | `write_file("personas.md", research)` |
| Generate journey maps | ✓ | ✗ | Create in response |

### Accessibility Auditor

| Task | Internal Only | Requires Tool | Tool & Usage |
|------|--------------|---------------|--------------|
| Review component code | ✗ | ✓ | `read_file("Component.jsx")` |
| Generate audit report | ✓ | ✗ | Create in response |
| Fix accessibility issues | ✗ | ✓ | `write_file("Component.jsx", fixedCode)` |
| Run accessibility check | ✗ | ✓ | `run_shell_command("npm run a11y-check")` |

## Command-Specific Tool Mappings

### extract-design-dna

```javascript
// Step 1: Read inspiration (if local file)
if (isLocalFile) {
  tool: read_file("inspiration/image.png")
  purpose: "View inspiration image"
}

// Step 2: Analyze internally
tool: NONE
purpose: "Extract patterns and create tokens"

// Step 3: Save tokens (optional)
if (userRequestsSave) {
  tool: write_file("design-tokens.json", extractedTokens)
  purpose: "Persist design DNA"
}
```

### create-ui-variations

```javascript
// Step 1: Check existing components
tool: list_files("src/components/")
purpose: "Understand current structure"

// Step 2: Generate variations internally
tool: NONE
purpose: "Create 3-5 variations in response"

// Step 3: Save selected variation
if (userSelectsVariation) {
  tool: write_file("components/SelectedVariation.jsx", code)
  purpose: "Save chosen design"
}
```

### audit-accessibility

```javascript
// Step 1: Read component to audit
tool: read_file("path/to/Component.jsx")
purpose: "Analyze current implementation"

// Step 2: Perform audit internally
tool: NONE
purpose: "Check WCAG compliance"

// Step 3: Save fixes
if (issuesFound) {
  tool: write_file("path/to/Component.jsx", accessibleCode)
  purpose: "Apply accessibility fixes"
}

// Step 4: Run validation
tool: run_shell_command("npm run accessibility-test")
purpose: "Verify fixes"
```

## Decision Trees for Tool Usage

### Should I Use a Tool?

```
User Request Analysis:
├─ "Show me" / "Generate" / "Create"
│  └─ Internal generation → Present in response
├─ "Save this" / "Create a file"
│  └─ Use write_file → Save to filesystem
├─ "Analyze existing" / "Review current"
│  └─ Use read_file → Load and analyze
├─ "Set up" / "Install" / "Configure"
│  └─ Use run_shell_command → System operations
└─ "Find" / "Search for"
   └─ Use search_file_content → Locate patterns
```

### Multi-Step Operations

```
Complex Task Breakdown:
1. Research Phase
   - read_file (existing work)
   - list_files (structure)
   - Internal analysis

2. Generation Phase
   - Internal creation
   - Response presentation
   
3. Persistence Phase
   - write_file (if requested)
   - run_shell_command (if building)
```

## Tool Usage Best Practices

### 1. Explicit Tool Announcements
Always announce tool usage:
```
"I'll read your existing component to understand the current structure..."
[Uses read_file]

"Let me save this design system configuration for you..."
[Uses write_file]
```

### 2. Batch Operations
Combine related tool operations:
```javascript
// Good: Batch related file writes
const files = [
  { path: "tokens.json", content: tokens },
  { path: "components/Button.jsx", content: buttonCode },
  { path: "components/Card.jsx", content: cardCode }
];
files.forEach(f => write_file(f.path, f.content));

// Avoid: Scattered operations
```

### 3. Validation After Changes
```javascript
// After generating and saving
write_file("Component.jsx", newCode);
run_shell_command("npm run lint Component.jsx");
run_shell_command("npm run test Component.test.jsx");
```

### 4. Safe File Operations
```javascript
// Check before overwriting
const existing = read_file("important.config.js");
if (existing && !userConfirmedOverwrite) {
  ask("This file exists. Overwrite?");
}
```

## Common Patterns

### Pattern 1: Analyze → Generate → Save
```
1. read_file("existing-design.jsx") // Understand context
2. Internal generation // Create improvements
3. Present options // Show in response
4. write_file("new-design.jsx", selected) // Save choice
```

### Pattern 2: Research → Design → Deploy
```
1. list_files("src/") // Map structure
2. search_file_content("theme", "src/") // Find patterns
3. Internal design // Create components
4. write_file (multiple) // Save system
5. run_shell_command("npm run build") // Verify
```

### Pattern 3: Iterate → Test → Refine
```
1. read_file("Component.jsx") // Current version
2. Internal improvements // Apply feedback
3. write_file("Component.jsx", updated) // Save changes
4. run_shell_command("npm test") // Validate
5. Repeat as needed
```

## Error Handling

### Tool Failure Responses

| Tool Error | Response Strategy |
|------------|-------------------|
| File not found | Suggest alternatives, ask for correct path |
| Permission denied | Explain issue, suggest different location |
| Command failed | Show error, provide debugging steps |
| Write conflict | Ask user preference, offer backup |

## Integration with Memory Patterns

When using tools with memory operations:

```javascript
// Recall + Tool Usage
"Recalling your design preferences..."
const existingTokens = read_file("design-system/tokens.json");
"Merging with your stored preferences..."
const updatedTokens = mergeWithMemory(existingTokens, preferences);
write_file("design-system/tokens.json", updatedTokens);
```

---

*Tool Usage Matrix v1.0 | Explicit mapping for Claude Code tool integration*