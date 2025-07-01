# Tool Usage Preservation Guide

Guidelines and standards for maintaining explicit tool usage documentation across all UI Designer Claude patterns and components.

## Core Principles

### 1. Explicit Over Implicit
Every pattern must clearly distinguish between:
- **Internal Operations**: Conceptual reasoning, analysis, and decision-making
- **Tool Operations**: External actions requiring specific Claude Code tools
- **Hybrid Operations**: Combinations where tools enhance internal processes

### 2. Tabular Documentation Standard
All patterns must include tool integration tables following this format:

```markdown
| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|---------|
| 1. [Step name] | [What happens] | `tool_name()` or None | [Why this choice] |
```

### 3. Progressive Tool Disclosure
- Start with high-level overview
- Provide detailed step-by-step breakdowns
- Include concrete code examples
- Show actual tool invocations

### 4. Rationale Documentation
Always explain:
- Why a tool is needed vs. internal processing
- When to use each tool
- What alternatives were considered
- Performance implications

## Standard Table Format

### Basic Tool Integration Table
```markdown
## Tool Integration

| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|---------|
| 1. Analyze request | Parse user input | None (internal analysis) | Understand intent |
| 2. Check existing work | Load current files | `read_file("path/to/file")` | Get current state |
| 3. Generate solution | Create new content | None (internal generation) | Apply patterns |
| 4. Save results | Persist to filesystem | `write_file("path/to/file", content)` | Store output |
| 5. Verify success | Check file creation | `list_files("directory/")` | Confirm operation |
```

### Extended Format with Conditions
```markdown
## Conditional Tool Usage

| Condition | Action | Tool to Use | Alternative |
|-----------|--------|-------------|-------------|
| If file exists | Read and modify | `read_file()` → `write_file()` | Create new |
| If pattern found | Update in place | `search_file_content()` → `edit_file()` | Add new section |
| If performance critical | Batch process | `batch_operations()` | Sequential processing |
```

## Pattern Categories

### 1. Analysis Patterns
Primarily internal with selective tool usage:
```markdown
| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|---------|
| 1. Visual analysis | Extract patterns | None (internal) | Identify design DNA |
| 2. Verify examples | Check similar files | `search_file_content("pattern")` | Find precedents |
| 3. Document findings | Generate report | None (internal) | Create analysis |
```

### 2. Generation Patterns
Mixed internal and tool operations:
```markdown
| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|---------|
| 1. Plan structure | Design architecture | None (internal) | Create blueprint |
| 2. Check conflicts | Verify uniqueness | `list_files()` | Avoid overwrites |
| 3. Generate content | Create components | None (internal) | Apply patterns |
| 4. Save all files | Write to disk | `write_file()` (multiple) | Persist work |
```

### 3. Modification Patterns
Tool-heavy operations:
```markdown
| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|---------|
| 1. Load current | Read existing files | `read_file()` (multiple) | Get current state |
| 2. Find patterns | Search codebase | `search_file_content()` | Locate targets |
| 3. Apply changes | Modify files | `edit_file()` | Update content |
| 4. Validate changes | Run checks | `run_shell_command()` | Ensure correctness |
```

## Multi-Agent Tool Transparency

### Standard Agent Task Definition
```javascript
const agentTaskDefinition = {
  agent: "Specialist Name",
  description: "What this agent does",
  
  toolUsage: {
    required: ["read_file", "write_file"],
    optional: ["search_file_content", "list_files"],
    forbidden: ["delete_file", "run_shell_command"],
    
    sequence: {
      phase1: ["read_file", "list_files"],
      phase2: ["internal processing"],
      phase3: ["write_file"]
    },
    
    rationale: {
      read_file: "Must read existing patterns to maintain consistency",
      write_file: "Persists new patterns for future use",
      forbidden: "No destructive operations allowed"
    }
  },
  
  example: `
    // Phase 1: Discovery
    const existing = read_file("patterns/current.md");
    const structure = list_files("patterns/");
    
    // Phase 2: Processing (internal)
    const enhanced = processPattern(existing);
    
    // Phase 3: Persistence
    write_file("patterns/enhanced.md", enhanced);
  `
};
```

### Orchestration Documentation
```javascript
// When using Task() for multi-agent work
const multiAgentOrchestration = {
  overview: "6 agents working in parallel",
  
  agentTools: [
    {
      name: "Pattern Analyzer",
      tools: ["read_file", "search_file_content"],
      purpose: "Read and analyze existing patterns"
    },
    {
      name: "Pattern Generator", 
      tools: ["write_file"],
      purpose: "Create new pattern files"
    },
    {
      name: "Integration Agent",
      tools: ["read_file", "edit_file", "write_file"],
      purpose: "Modify existing files to add integration"
    }
  ],
  
  coordination: "Parallel execution with final integration phase"
};
```

## Code Examples

### Good: Explicit Tool Documentation
```javascript
// Step 1: Check if pattern exists (Tool: list_files)
const patterns = list_files(".claude/patterns/");
if (patterns.includes("target-pattern.md")) {
  // Step 2: Read existing pattern (Tool: read_file)
  const content = read_file(".claude/patterns/target-pattern.md");
  
  // Step 3: Enhance pattern (Internal processing)
  const enhanced = addToolIntegrationTable(content);
  
  // Step 4: Save updated pattern (Tool: write_file)
  write_file(".claude/patterns/target-pattern.md", enhanced);
}
```

### Bad: Implicit Tool Usage
```javascript
// Vague comment about "processing files"
processPatterns(); // What tools does this use?
updateDocumentation(); // Is this internal or external?
```

## Validation Checklist

Before finalizing any pattern, ensure:

- [ ] **Tool Integration Table**: Present and complete
- [ ] **Step Numbering**: Sequential and clear
- [ ] **Tool Specifications**: Exact tool names with parameters
- [ ] **Purpose Column**: Explains why each tool/approach is chosen
- [ ] **Code Examples**: Show actual tool invocations
- [ ] **Alternatives**: Document when NOT to use tools
- [ ] **Multi-Agent**: If applicable, agent tool usage is documented
- [ ] **Rationale**: Clear explanation of tool vs. internal decisions

## Common Patterns Reference

### Reading Operations
```markdown
| Pattern | When to Use Tool | When Internal |
|---------|------------------|---------------|
| Analyze existing code | `read_file()` - Always | Never - Can't assume content |
| Check file existence | `list_files()` | Internal if from previous step |
| Search for patterns | `search_file_content()` | Internal for generated content |
```

### Writing Operations
```markdown
| Pattern | When to Use Tool | When Internal |
|---------|------------------|---------------|
| Save to disk | `write_file()` - Always | Never - Must persist |
| Update existing | `edit_file()` or `write_file()` | Never - Must modify file |
| Display to user | Never - Show in response | Always - Direct communication |
```

### Processing Operations
```markdown
| Pattern | When to Use Tool | When Internal |
|---------|------------------|---------------|
| Generate designs | Never | Always - Creative work |
| Transform data | `run_shell_command()` if complex | Simple transformations |
| Validate syntax | `run_shell_command()` for linters | Basic checks |
```

## Migration Guide

### For Existing Patterns
1. Identify all tool usage (explicit and implicit)
2. Create tool integration table
3. Add rationale for each tool choice
4. Include code examples
5. Document multi-agent usage if applicable

### For New Patterns
1. Start with tool integration table
2. Design with explicit tool boundaries
3. Document rationale upfront
4. Include validation criteria
5. Follow examples from this guide

## Maintenance

This guide should be updated when:
- New tools become available
- Best practices evolve
- Common patterns emerge
- Edge cases are discovered

Regular audits should ensure all patterns maintain these standards.

---

*Tool Usage Preservation Guide v1.0 | Maintaining clarity in cognitive evolution*