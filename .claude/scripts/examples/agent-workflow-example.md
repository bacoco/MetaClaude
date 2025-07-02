# Agent Workflow Example: Using the Global Script Registry

This example demonstrates how MetaClaude agents use the Global Script Registry to execute tools in their workflows.

## Example 1: API-UI Designer Using JSON Validation

```markdown
# API Response Validation Workflow

## Phase 1: Validate API Response Structure

- step: "Load API schema"
  action: read_file
  path: "./api/user-schema.json"
  outputs_to: "user_schema"

- step: "Get API response"
  action: api_call
  endpoint: "/api/users/123"
  outputs_to: "api_response"

- step: "Validate response against schema"
  action: use_tool
  tool_id: "core/json-validator"
  inputs:
    schema_path: "./api/user-schema.json"
    data_path: "./temp/api-response.json"
  outputs_to: "validation_result"
  on_error: "handle_validation_failure"

- step: "Process valid response"
  condition: "validation_result.is_valid == true"
  action: generate_ui_components
  data: "api_response"
```

## Example 2: Data Scientist Processing CSV Data

```markdown
# Data Processing Pipeline

## Phase 1: Data Preparation

- step: "Convert CSV to JSON for analysis"
  action: use_tool
  tool_id: "data/csv-to-json"
  inputs:
    input_file: "./data/sales-2024.csv"
    output_file: "./processed/sales-2024.json"
    headers: true
  outputs_to: "converted_data"

- step: "Log conversion results"
  action: log
  message: "Converted {converted_data.row_count} rows from CSV"

## Phase 2: Data Validation

- step: "Validate data structure"
  action: use_tool
  tool_id: "validation/json-schema-validator"
  inputs:
    schema_path: "./schemas/sales-data.schema.json"
    data_path: "./processed/sales-2024.json"
  outputs_to: "validation_status"

- step: "Proceed with analysis"
  condition: "validation_status.is_valid == true"
  action: run_analysis
  data_path: "./processed/sales-2024.json"
```

## Example 3: QA Engineer Analyzing Code Complexity

```markdown
# Code Quality Assessment

## Phase 1: Complexity Analysis

- step: "Analyze backend code complexity"
  action: use_tool
  tool_id: "analysis/code-complexity"
  inputs:
    source_path: "./src/backend"
    language: "typescript"
    format: "json"
  outputs_to: "backend_metrics"

- step: "Analyze frontend code complexity"
  action: use_tool
  tool_id: "analysis/code-complexity"
  inputs:
    source_path: "./src/frontend"
    language: "javascript"
    format: "json"
  outputs_to: "frontend_metrics"

- step: "Generate complexity report"
  action: generate_report
  template: "complexity-report"
  data:
    backend: "backend_metrics"
    frontend: "frontend_metrics"
  output: "./reports/code-complexity.md"
```

## Example 4: Multi-Agent Collaboration

```markdown
# Cross-Specialist Tool Sharing

## Scenario: API-UI Designer creates mock data for QA Engineer

### API-UI Designer Workflow

- step: "Generate mock user data"
  action: use_tool
  tool_id: "generation/api-mock"
  inputs:
    schema:
      type: "object"
      properties:
        id: { type: "string", format: "uuid" }
        name: { type: "string" }
        email: { type: "string", format: "email" }
        age: { type: "number", minimum: 18, maximum: 100 }
    count: 50
    seed: 12345
  outputs_to: "mock_users"

- step: "Save mock data for QA"
  action: write_file
  path: "./test-data/mock-users.json"
  content: "mock_users.mock_data"

- step: "Notify QA Engineer"
  action: send_message
  to: "qa-engineer"
  message: "Mock data ready at ./test-data/mock-users.json"

### QA Engineer Workflow

- step: "Validate mock data"
  action: use_tool
  tool_id: "validation/json-schema-validator"
  inputs:
    schema_path: "./api/user-schema.json"
    data_path: "./test-data/mock-users.json"
  outputs_to: "mock_validation"

- step: "Use mock data in tests"
  condition: "mock_validation.is_valid == true"
  action: generate_test_cases
  data_source: "./test-data/mock-users.json"
```

## Tool Discovery in Workflows

```markdown
# Dynamic Tool Discovery

- step: "Find available validation tools"
  action: search_tools
  category: "validation"
  tags: ["json", "schema"]
  outputs_to: "available_validators"

- step: "Select best validator"
  action: select_tool
  from: "available_validators"
  criteria:
    - "supports_json_schema"
    - "performance_rating > 4"
  outputs_to: "selected_validator"

- step: "Execute selected validator"
  action: use_tool
  tool_id: "selected_validator.id"
  inputs:
    schema_path: "./schema.json"
    data_path: "./data.json"
```

## Error Handling with Tools

```markdown
# Robust Tool Execution

- step: "Attempt data conversion"
  action: use_tool
  tool_id: "data/csv-to-json"
  inputs:
    input_file: "./raw/data.csv"
  outputs_to: "conversion_result"
  on_error: "handle_conversion_error"
  error_outputs_to: "conversion_error"

- step: "Handle conversion error"
  id: "handle_conversion_error"
  condition: "conversion_error != null"
  actions:
    - log_error: "conversion_error.message"
    - use_fallback_tool: "data/csv-parser-basic"
    - notify_user: "Data conversion failed, using fallback parser"
```

## Best Practices

1. **Always specify outputs_to**: Capture tool outputs for use in subsequent steps
2. **Handle errors gracefully**: Use on_error to define fallback behavior
3. **Validate inputs**: Ensure data is in the expected format before tool execution
4. **Use conditions**: Check tool outputs before proceeding
5. **Log important events**: Track tool execution for debugging
6. **Leverage parallel execution**: Run independent tools concurrently

## Integration with TES

When an agent's workflow includes `action: use_tool`, the orchestration layer:

1. Looks up the tool in the registry
2. Validates the provided inputs against the tool's schema
3. Invokes the Tool Execution Service (TES) with appropriate sandboxing
4. Captures outputs and errors
5. Makes results available to the workflow via the specified variable names

This ensures secure, validated, and consistent tool execution across all specialists.

---

*Example demonstrates prose-as-code tool usage in MetaClaude workflows*