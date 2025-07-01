# Test Case Generator Examples

This directory contains practical examples demonstrating the capabilities of the Automated Test Case Generator.

## Directory Structure

```
examples/
├── requirements/          # Sample requirement documents
├── generated-tests/       # Example outputs from test generation
└── workflows/            # Custom workflow examples
```

## Quick Start Examples

### 1. Basic Test Generation
```bash
# Generate tests from the e-commerce checkout requirements
./claude-flow sparc "Generate test cases from examples/requirements/e-commerce-checkout.md"
```

### 2. View Generated Test Plan
```bash
# Examine the example test plan structure
cat examples/generated-tests/checkout-test-plan.json | jq .
```

### 3. BDD Scenarios
```bash
# View generated Cucumber scenarios
cat examples/generated-tests/checkout.feature
```

### 4. Custom Workflow
```bash
# Try the custom API testing workflow
./claude-flow workflow examples/workflows/custom-api-testing.md \
  --openapi-spec your-api-spec.yaml
```

## Available Examples

### Requirements Documents
- **e-commerce-checkout.md**: Comprehensive checkout process requirements with acceptance criteria, business rules, and edge cases

### Generated Tests
- **checkout-test-plan.json**: Complete test plan with 47 test cases, execution strategy, and traceability matrix
- **checkout.feature**: BDD scenarios covering happy paths, validations, edge cases, and non-functional requirements

### Workflows
- **custom-api-testing.md**: Advanced workflow for generating API tests from OpenAPI specifications

## Learning Path

1. **Start Simple**: Read `e-commerce-checkout.md` to understand input format
2. **Examine Output**: Study `checkout-test-plan.json` to see generated structure
3. **BDD Format**: Review `checkout.feature` for Cucumber-style tests
4. **Advanced Usage**: Explore `custom-api-testing.md` for complex workflows

## Creating Your Own Examples

1. Copy an existing example as a template
2. Modify for your specific use case
3. Run the test generator
4. Share successful examples with the team

## Tips

- Well-structured requirements lead to better test generation
- Include acceptance criteria for comprehensive coverage
- Document edge cases in requirements for better discovery
- Use consistent terminology throughout documents

For more information, see the main documentation in `/docs`.