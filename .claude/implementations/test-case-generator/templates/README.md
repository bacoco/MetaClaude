# Test Case Generator Templates

This directory contains reusable templates for various testing artifacts. These templates can be used as starting points for test generation or customized for specific project needs.

## Available Templates

### 1. test-case-template.md
A comprehensive template for documenting individual test cases with all necessary details including:
- Test case metadata (ID, priority, type)
- Prerequisites and test data
- Step-by-step execution instructions
- Expected results and post-conditions

**Usage**:
```bash
./claude-flow sparc "Generate test cases using templates/test-case-template.md format"
```

### 2. bdd-scenario-template.feature
A Gherkin format template for Behavior-Driven Development scenarios including:
- Feature descriptions with user stories
- Various scenario types (happy path, edge cases, negative tests)
- Data tables and scenario outlines
- Tags for test organization

**Usage**:
```bash
./claude-flow sparc "Create BDD scenarios based on templates/bdd-scenario-template.feature"
```

### 3. api-test-template.yaml
A structured template for API testing covering:
- Authentication setup
- Happy path tests
- Validation and error handling
- Performance and security tests
- Test data and environment configuration

**Usage**:
```bash
./claude-flow sparc "Generate API tests using templates/api-test-template.yaml structure"
```

### 4. test-plan-template.md
A complete test plan document template including:
- Test objectives and scope
- Resource requirements
- Risk analysis
- Execution schedule
- Entry/exit criteria

**Usage**:
```bash
./claude-flow sparc "Create test plan based on templates/test-plan-template.md"
```

## Customizing Templates

### 1. Project-Specific Templates
Copy and modify templates for your project:
```bash
cp test-case-template.md my-project-test-template.md
# Edit to add project-specific fields
```

### 2. Industry-Specific Templates
Create specialized templates for different domains:
- Financial services (include compliance checks)
- Healthcare (add HIPAA validation)
- E-commerce (focus on payment flows)
- Gaming (performance and load testing)

### 3. Framework-Specific Templates
Adapt templates for specific test frameworks:
- Jest/Mocha for JavaScript
- pytest for Python
- JUnit for Java
- RSpec for Ruby

## Using Templates with Claude Flow

### Direct Template Usage
```bash
# Use template as-is
./claude-flow sparc "Generate tests following the exact structure in templates/test-case-template.md"
```

### Template Enhancement
```bash
# Enhance template with project context
./claude-flow memory store "project_context" "E-commerce platform with focus on mobile"
./claude-flow sparc "Generate tests using api-test-template.yaml adapted for our project context"
```

### Batch Processing with Templates
```bash
# Generate multiple test types using templates
./claude-flow sparc "For each feature in requirements/, generate:
1. Test cases using test-case-template.md
2. BDD scenarios using bdd-scenario-template.feature
3. API tests using api-test-template.yaml"
```

## Template Best Practices

### 1. Maintain Consistency
- Use consistent naming conventions
- Keep similar structure across templates
- Document template usage guidelines

### 2. Version Control
- Track template changes in git
- Document template modifications
- Create template change logs

### 3. Template Libraries
Build collections of templates for:
- Different test types
- Various project phases
- Specific technologies
- Compliance requirements

### 4. Regular Updates
- Review templates quarterly
- Incorporate lessons learned
- Update based on tool changes
- Add new test patterns

## Contributing Templates

To contribute a new template:

1. Create template following existing patterns
2. Include comprehensive examples
3. Add usage documentation
4. Test with Claude Flow
5. Submit with example outputs

## Template Variables

Common variables used across templates:

```yaml
variables:
  PROJECT_NAME: "Your Project"
  TEST_ENVIRONMENT: "QA"
  VERSION: "1.0.0"
  TESTER_NAME: "Your Name"
  DATE: "YYYY-MM-DD"
  
  # Test data variables
  BASE_URL: "https://test.example.com"
  TEST_USER: "testuser@example.com"
  API_KEY: "your-api-key"
```

## Quick Reference

| Template | Best For | Output Format |
|----------|----------|---------------|
| test-case-template.md | Manual testing, documentation | Markdown |
| bdd-scenario-template.feature | Automation, behavior testing | Gherkin |
| api-test-template.yaml | API testing, integration | YAML/JSON |
| test-plan-template.md | Project planning, management | Markdown |

---

For more information on using these templates effectively, see the [Best Practices Guide](../docs/best-practices.md).