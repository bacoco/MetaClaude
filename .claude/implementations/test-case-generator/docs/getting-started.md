# Getting Started with Test Case Generator

## Introduction
Welcome to the Automated Test Case Generator specialist for Claude Flow. This guide will help you quickly start generating comprehensive test cases from your requirements, user stories, or existing documentation.

## Prerequisites

### System Requirements
- Claude Flow CLI installed and configured
- Access to Claude API (authenticated)
- Node.js 16+ (for test framework integration)
- Git (for version control)

### Knowledge Requirements
- Basic understanding of software testing concepts
- Familiarity with test case structure
- Command line basics

## Quick Start (5 Minutes)

### 1. Verify Installation
```bash
# Check Claude Flow is installed
./claude-flow --version

# Verify test generator specialist
./claude-flow list-specialists | grep test-case-generator
```

### 2. Your First Test Generation
```bash
# Generate test cases from a simple requirement
echo "Users should be able to login with email and password" > requirement.txt

# Run the test generator
./claude-flow sparc "Generate test cases from requirement.txt"
```

### 3. View Generated Tests
The generator will create:
- Test cases in JSON format
- BDD scenarios (if applicable)
- Edge cases and boundary conditions
- Test execution plan

## Basic Workflows

### Workflow 1: Generate Tests from User Story
```bash
# Create a user story file
cat > user-story.md << EOF
## User Story: Password Reset
As a registered user
I want to reset my password
So that I can regain access to my account

### Acceptance Criteria
- User receives reset email within 5 minutes
- Reset link expires after 24 hours
- New password must meet security requirements
EOF

# Generate comprehensive test cases
./claude-flow sparc "Generate test cases from user-story.md including edge cases"
```

### Workflow 2: BDD Scenario Generation
```bash
# Generate Cucumber-compatible scenarios
./claude-flow workflow bdd-scenario-generation.md \
  --input "user-story.md" \
  --output "features/"

# View generated feature file
cat features/password-reset.feature
```

### Workflow 3: Edge Case Discovery
```bash
# Discover edge cases for existing feature
./claude-flow workflow edge-case-discovery.md \
  --feature "login-form" \
  --risk-level "all"
```

## Understanding the Output

### Test Case Structure
```json
{
  "test_case": {
    "id": "TC-001",
    "title": "Successful password reset",
    "description": "Verify user can reset password with valid email",
    "preconditions": [
      "User account exists",
      "User has valid email address"
    ],
    "steps": [
      {
        "step": 1,
        "action": "Navigate to login page",
        "expected": "Login page displays"
      },
      {
        "step": 2,
        "action": "Click 'Forgot Password' link",
        "expected": "Password reset page displays"
      }
    ],
    "test_data": {
      "email": "user@example.com"
    },
    "priority": "High",
    "type": "Functional"
  }
}
```

### BDD Scenario Format
```gherkin
Feature: Password Reset

  Scenario: Successful password reset
    Given I am on the login page
    When I click "Forgot Password"
    And I enter "user@example.com" as email
    And I click "Send Reset Link"
    Then I should see "Reset link sent" message
    And I should receive an email within 5 minutes
```

## Common Use Cases

### 1. API Testing
```bash
# Generate API test cases from OpenAPI spec
./claude-flow sparc "Generate API test cases from swagger.yaml"

# Output includes:
# - Endpoint testing scenarios
# - Request/response validation
# - Error handling cases
# - Authentication tests
```

### 2. E2E Testing
```bash
# Generate end-to-end test scenarios
./claude-flow sparc "Create E2E test cases for checkout process"

# Includes:
# - User journey scenarios
# - Cross-feature interactions
# - State validation
# - Integration points
```

### 3. Regression Suite
```bash
# Build regression test suite from requirements
./claude-flow sparc "Create regression test suite from requirements/"

# Generates:
# - Core functionality tests
# - Critical path coverage
# - Backward compatibility tests
# - Smoke test subset
```

## Configuration Options

### Basic Configuration
```yaml
# .claude/test-generator-config.yaml
test_generator:
  default_priority: "Medium"
  include_edge_cases: true
  output_formats: ["json", "markdown", "gherkin"]
  test_types:
    - functional
    - integration
    - performance
  coverage_target: 95
```

### Advanced Settings
```yaml
# Advanced configuration options
test_generator:
  agents:
    requirements_interpreter:
      depth: "comprehensive"
      ambiguity_detection: true
    scenario_builder:
      style: "bdd"
      detail_level: "high"
    edge_case_identifier:
      categories: ["security", "performance", "boundary"]
      risk_threshold: "medium"
  execution:
    parallel_generation: true
    cache_results: true
    incremental_mode: false
```

## Integration with Test Frameworks

### Cypress Integration
```bash
# Generate Cypress test specs
./claude-flow sparc "Generate Cypress tests from requirements.md"

# Output location
cypress/e2e/generated/
```

### Jest Integration
```bash
# Generate Jest test suites
./claude-flow sparc "Create Jest unit tests for user service from API spec"

# Output location
__tests__/generated/
```

### Playwright Integration
```bash
# Generate Playwright test scripts
./claude-flow sparc "Generate Playwright E2E tests for login flow"

# Output location
tests/e2e/generated/
```

## Tips for Better Results

### 1. Provide Clear Requirements
- Include acceptance criteria
- Specify edge cases if known
- Document dependencies
- Use consistent terminology

### 2. Iterative Refinement
```bash
# Generate initial tests
./claude-flow sparc "Generate test cases from requirements"

# Review and refine
./claude-flow sparc "Add edge cases for error handling to existing tests"

# Enhance with performance tests
./claude-flow sparc "Add performance test scenarios"
```

### 3. Leverage Memory
```bash
# Store project context
./claude-flow memory store "project_context" "E-commerce platform with focus on payment security"

# Future generations will use this context
./claude-flow sparc "Generate test cases for new payment feature"
```

## Troubleshooting

### Issue: Incomplete Test Coverage
**Solution**: Provide more detailed requirements
```bash
# Instead of: "User can login"
# Use: "User can login with email/password, social auth, or SSO"
```

### Issue: Too Many Test Cases
**Solution**: Use filtering and prioritization
```bash
./claude-flow sparc "Generate only critical and high priority test cases"
```

### Issue: Wrong Test Format
**Solution**: Specify output format explicitly
```bash
./claude-flow sparc "Generate test cases in Gherkin format for Cucumber"
```

## Next Steps

1. **Explore Workflows**: Try the pre-built workflows in `/workflows`
2. **Customize Agents**: Configure agent behavior for your needs
3. **Build Templates**: Create reusable test case templates
4. **Integrate CI/CD**: Add test generation to your pipeline
5. **Read Best Practices**: See `best-practices.md` for advanced usage

## Getting Help

```bash
# View available commands
./claude-flow help test-case-generator

# Check documentation
ls .claude/implementations/test-case-generator/docs/

# Interactive help
./claude-flow sparc "Help me generate test cases for my specific use case"
```

## Quick Reference Card

| Task | Command |
|------|---------|
| Generate from requirements | `./claude-flow sparc "Generate tests from requirements.md"` |
| Create BDD scenarios | `./claude-flow workflow bdd-scenario-generation.md` |
| Find edge cases | `./claude-flow workflow edge-case-discovery.md` |
| Build test plan | `./claude-flow workflow prd-to-test-plan.md` |
| API test generation | `./claude-flow sparc "Generate API tests from swagger.yaml"` |
| E2E test creation | `./claude-flow sparc "Create E2E tests for user journey"` |

---

Ready to generate comprehensive test cases? Start with your requirements and let the Test Case Generator do the heavy lifting!