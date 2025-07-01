# Custom API Testing Workflow

## Overview
This example workflow demonstrates how to create a custom test generation workflow for API testing, combining multiple agents to create comprehensive API test suites.

## Workflow Definition

```yaml
workflow:
  name: "API Test Generation"
  version: "1.0.0"
  description: "Generate comprehensive API tests from OpenAPI specifications"
  
  inputs:
    - openapi_spec: "Path to OpenAPI/Swagger file"
    - test_depth: "shallow|standard|comprehensive"
    - include_security: "boolean"
    - include_performance: "boolean"
  
  outputs:
    - postman_collection: "Generated Postman collection"
    - test_scripts: "Automated test scripts"
    - edge_cases: "API-specific edge cases"
    - documentation: "Test documentation"
```

## Workflow Stages

### Stage 1: API Specification Analysis
```bash
# Parse OpenAPI specification
./claude-flow agent spawn requirements-interpreter \
  --input "api/openapi.yaml" \
  --mode "api-spec" \
  --output "parsed-api.json"
```

**Duration**: 5-10 minutes  
**Output**: Structured API endpoints, parameters, schemas

### Stage 2: Test Scenario Generation
```bash
# Generate test scenarios for each endpoint
./claude-flow agent spawn scenario-builder \
  --input "parsed-api.json" \
  --type "api" \
  --coverage "endpoint,method,status-code" \
  --output "api-scenarios.json"
```

**Duration**: 15-20 minutes  
**Output**: Test scenarios for all endpoints

### Stage 3: Security Test Generation
```bash
# Generate security-specific tests
./claude-flow sparc "Generate OWASP Top 10 security tests for API endpoints"
```

**Output**:
- Authentication bypass tests
- Injection attack scenarios
- Rate limiting tests
- Authorization matrix tests

### Stage 4: Edge Case Discovery
```bash
# Find API-specific edge cases
./claude-flow agent spawn edge-case-identifier \
  --input "api-scenarios.json" \
  --focus "api-boundaries,payload-limits,encoding" \
  --output "api-edge-cases.json"
```

**Output**:
- Boundary value tests
- Malformed request tests
- Encoding edge cases
- Concurrent request scenarios

### Stage 5: Performance Test Scenarios
```bash
# Generate performance test scenarios
./claude-flow sparc "Create load test scenarios for API endpoints based on SLA requirements"
```

**Output**:
- Load test scripts
- Stress test scenarios
- Spike test configurations
- Endurance test plans

### Stage 6: Test Artifact Generation
```bash
# Generate various test artifacts
./claude-flow agent spawn test-plan-architect \
  --scenarios "api-scenarios.json" \
  --edge-cases "api-edge-cases.json" \
  --format "postman,k6,pytest" \
  --output "test-artifacts/"
```

## Generated Artifacts

### 1. Postman Collection
```json
{
  "info": {
    "name": "E-Commerce API Tests",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "User Authentication",
      "item": [
        {
          "name": "Login - Success",
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/api/auth/login",
            "body": {
              "mode": "raw",
              "raw": {
                "email": "{{testEmail}}",
                "password": "{{testPassword}}"
              }
            }
          },
          "test": [
            "pm.test('Status code is 200', () => {",
            "  pm.response.to.have.status(200);",
            "});",
            "pm.test('Response has token', () => {",
            "  const jsonData = pm.response.json();",
            "  pm.expect(jsonData).to.have.property('token');",
            "});"
          ]
        }
      ]
    }
  ]
}
```

### 2. K6 Performance Test
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    errors: ['rate<0.1'],             // Error rate < 10%
    http_req_duration: ['p(95)<500'], // 95% of requests < 500ms
  },
};

export default function() {
  // Login test
  const loginRes = http.post(`${__ENV.API_URL}/api/auth/login`, {
    email: 'test@example.com',
    password: 'password123',
  });
  
  check(loginRes, {
    'login successful': (r) => r.status === 200,
    'token received': (r) => r.json('token') !== undefined,
  });
  
  errorRate.add(loginRes.status !== 200);
  
  sleep(1);
}
```

### 3. PyTest API Tests
```python
# test_api_checkout.py
import pytest
import requests
from datetime import datetime

class TestCheckoutAPI:
    """Generated test cases for Checkout API endpoints"""
    
    @pytest.fixture
    def auth_headers(self):
        """Get authenticated headers"""
        response = requests.post(
            f"{BASE_URL}/api/auth/login",
            json={"email": "test@example.com", "password": "password123"}
        )
        token = response.json()["token"]
        return {"Authorization": f"Bearer {token}"}
    
    def test_create_order_success(self, auth_headers):
        """Test successful order creation"""
        order_data = {
            "items": [
                {"product_id": "PROD-001", "quantity": 2},
                {"product_id": "PROD-002", "quantity": 1}
            ],
            "shipping_address": {
                "street": "123 Main St",
                "city": "New York",
                "state": "NY",
                "zip": "10001"
            },
            "payment_method": "credit_card"
        }
        
        response = requests.post(
            f"{BASE_URL}/api/orders",
            json=order_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        assert "order_id" in response.json()
        assert response.json()["status"] == "pending"
    
    @pytest.mark.parametrize("invalid_field,invalid_value,expected_error", [
        ("items", [], "Items cannot be empty"),
        ("items", [{"product_id": "INVALID"}], "Missing quantity"),
        ("shipping_address", {}, "Address required"),
        ("payment_method", "bitcoin", "Invalid payment method")
    ])
    def test_create_order_validation(self, auth_headers, invalid_field, invalid_value, expected_error):
        """Test order creation with invalid data"""
        order_data = {
            "items": [{"product_id": "PROD-001", "quantity": 1}],
            "shipping_address": {"street": "123 Main St", "city": "New York"},
            "payment_method": "credit_card"
        }
        
        # Override with invalid data
        order_data[invalid_field] = invalid_value
        
        response = requests.post(
            f"{BASE_URL}/api/orders",
            json=order_data,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert expected_error in response.json()["message"]
```

## Custom Workflow Execution

### Command Line Execution
```bash
# Run the complete workflow
./claude-flow workflow custom-api-testing.md \
  --openapi-spec "api/openapi.yaml" \
  --test-depth "comprehensive" \
  --include-security true \
  --include-performance true \
  --output-dir "generated-api-tests/"
```

### Programmatic Execution
```python
from claude_flow import Workflow, Agent

# Initialize workflow
workflow = Workflow("custom-api-testing.md")

# Configure agents
workflow.configure({
    "requirements_interpreter": {
        "mode": "api-spec",
        "extract_schemas": True
    },
    "scenario_builder": {
        "include_negative_tests": True,
        "status_codes": [200, 201, 400, 401, 403, 404, 500]
    },
    "edge_case_identifier": {
        "categories": ["security", "performance", "data-validation"]
    }
})

# Execute workflow
results = workflow.execute(
    openapi_spec="api/openapi.yaml",
    test_depth="comprehensive"
)

# Process results
print(f"Generated {results['total_tests']} test cases")
print(f"Coverage: {results['endpoint_coverage']}%")
```

## Customization Options

### 1. Add Custom Test Categories
```yaml
custom_categories:
  - name: "GDPR Compliance"
    tests:
      - "Data deletion verification"
      - "Data export functionality"
      - "Consent management"
  
  - name: "Multi-tenancy"
    tests:
      - "Tenant isolation"
      - "Cross-tenant access prevention"
      - "Tenant-specific rate limits"
```

### 2. Integration with CI/CD
```yaml
# .github/workflows/api-test-generation.yml
name: API Test Generation
on:
  push:
    paths:
      - 'api/openapi.yaml'

jobs:
  generate-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate API Tests
        run: |
          ./claude-flow workflow examples/workflows/custom-api-testing.md \
            --openapi-spec api/openapi.yaml \
            --test-depth comprehensive
      
      - name: Run Generated Tests
        run: |
          cd generated-api-tests
          npm install
          npm test
      
      - name: Upload Test Reports
        uses: actions/upload-artifact@v3
        with:
          name: api-test-reports
          path: generated-api-tests/reports/
```

### 3. Custom Validation Rules
```javascript
// custom-validations.js
module.exports = {
  validateResponse: (response, schema) => {
    // Custom business logic validation
    if (response.data.price && response.data.discount) {
      const finalPrice = response.data.price * (1 - response.data.discount);
      expect(response.data.finalPrice).toBe(finalPrice);
    }
  },
  
  validateBusinessRules: (testCase) => {
    // Ensure business rules are tested
    if (testCase.endpoint.includes('/orders')) {
      expect(testCase.scenarios).toContainEqual(
        expect.objectContaining({
          name: expect.stringContaining('minimum order value')
        })
      );
    }
  }
};
```

## Benefits of Custom Workflows

1. **Tailored to Your Needs**: Customize test generation for specific requirements
2. **Reusable**: Save and share workflows across teams
3. **Automated**: Integrate into CI/CD pipelines
4. **Comprehensive**: Combine multiple testing aspects
5. **Maintainable**: Update workflow as requirements evolve

## Next Steps

1. Copy this workflow template
2. Modify stages for your specific needs
3. Add custom validation rules
4. Integrate with your CI/CD pipeline
5. Share with your team

For more examples, see the `/workflows` directory.