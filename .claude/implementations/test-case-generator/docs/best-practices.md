# Test Case Generator Best Practices

## Overview
This document outlines best practices for using the Test Case Generator to create high-quality, maintainable test suites that provide comprehensive coverage while remaining efficient and manageable.

## Table of Contents
1. [Requirements Preparation](#requirements-preparation)
2. [Test Generation Strategy](#test-generation-strategy)
3. [Test Organization](#test-organization)
4. [Edge Case Management](#edge-case-management)
5. [Test Maintenance](#test-maintenance)
6. [Performance Optimization](#performance-optimization)
7. [Quality Assurance](#quality-assurance)
8. [Team Collaboration](#team-collaboration)

## Requirements Preparation

### 1. Write Clear Acceptance Criteria
**✅ Good Practice**
```markdown
## User Story: Shopping Cart Persistence
As a registered user
I want my shopping cart to persist between sessions
So that I don't lose my selected items

### Acceptance Criteria
- [ ] Cart items are saved when user logs out
- [ ] Cart items are restored when user logs back in
- [ ] Cart persists for 30 days maximum
- [ ] Guest cart merges with user cart on login
- [ ] Quantity limits are enforced (max 99 per item)
```

**❌ Poor Practice**
```markdown
User should be able to save cart
```

### 2. Include Non-Functional Requirements
```yaml
performance_requirements:
  - Cart operations complete within 500ms
  - Support 1000 concurrent cart updates
  - Cart data < 1MB per user

security_requirements:
  - Cart data encrypted at rest
  - Session tokens expire after 24 hours
  - Rate limiting on cart updates (100/hour)
```

### 3. Document Edge Cases Early
```markdown
### Known Edge Cases
1. User adds item that goes out of stock
2. Price changes while item is in cart
3. Promotional codes expire
4. Shipping address becomes invalid
5. Payment method expires
```

### 4. Use Consistent Terminology
```yaml
# terminology.yaml
glossary:
  cart: "Shopping cart containing products"
  basket: "Alias for cart - DO NOT USE"
  item: "Individual product in cart"
  product: "Sellable item in catalog"
  SKU: "Stock Keeping Unit - unique product identifier"
```

## Test Generation Strategy

### 1. Layered Test Approach
```bash
# Level 1: Unit Tests
./claude-flow sparc "Generate unit tests for cart service methods"

# Level 2: Integration Tests
./claude-flow sparc "Generate integration tests for cart API endpoints"

# Level 3: E2E Tests
./claude-flow sparc "Generate E2E tests for complete shopping journey"

# Level 4: Edge Cases
./claude-flow workflow edge-case-discovery.md --feature cart
```

### 2. Risk-Based Generation
```python
# Prioritize test generation based on risk
risk_matrix = {
    "payment_processing": {
        "business_impact": "critical",
        "failure_probability": "medium",
        "test_depth": "comprehensive"
    },
    "product_search": {
        "business_impact": "high",
        "failure_probability": "low",
        "test_depth": "standard"
    },
    "user_preferences": {
        "business_impact": "low",
        "failure_probability": "low",
        "test_depth": "basic"
    }
}

# Generate tests accordingly
for feature, risk in risk_matrix.items():
    if risk["test_depth"] == "comprehensive":
        # Generate extensive test suite with edge cases
        command = f"./claude-flow sparc 'Generate comprehensive tests for {feature} including edge cases and security scenarios'"
```

### 3. Progressive Test Generation
```bash
# Phase 1: Core functionality (Day 1)
./claude-flow sparc "Generate smoke tests for critical user paths"

# Phase 2: Full coverage (Day 2-3)
./claude-flow workflow prd-to-test-plan.md --depth standard

# Phase 3: Edge cases (Day 4)
./claude-flow workflow edge-case-discovery.md --depth comprehensive

# Phase 4: Performance tests (Day 5)
./claude-flow sparc "Generate performance test scenarios"
```

### 4. Context-Aware Generation
```bash
# Store project context
./claude-flow memory store "project_type" "e-commerce"
./claude-flow memory store "tech_stack" "React, Node.js, PostgreSQL"
./claude-flow memory store "testing_framework" "Jest, Cypress"

# Generate tests using context
./claude-flow sparc "Generate tests appropriate for our tech stack and project type"
```

## Test Organization

### 1. Feature-Based Structure
```
tests/
├── features/
│   ├── authentication/
│   │   ├── login.spec.js
│   │   ├── registration.spec.js
│   │   └── password-reset.spec.js
│   ├── shopping-cart/
│   │   ├── add-to-cart.spec.js
│   │   ├── update-quantity.spec.js
│   │   └── remove-item.spec.js
│   └── checkout/
│       ├── payment.spec.js
│       ├── shipping.spec.js
│       └── order-confirmation.spec.js
├── integration/
│   ├── api/
│   └── database/
└── e2e/
    ├── user-journeys/
    └── critical-paths/
```

### 2. Test Suite Metadata
```json
{
  "suite": "Shopping Cart Tests",
  "metadata": {
    "created": "2024-01-15",
    "last_updated": "2024-01-20",
    "coverage": {
      "requirements": ["CART-001", "CART-002", "CART-003"],
      "user_stories": ["US-101", "US-102"],
      "components": ["CartService", "CartAPI", "CartUI"]
    },
    "execution": {
      "duration": "15 minutes",
      "parallelizable": true,
      "dependencies": ["UserAuthentication", "ProductCatalog"]
    },
    "tags": ["@cart", "@critical", "@smoke"]
  }
}
```

### 3. Test Naming Conventions
```javascript
// Good test names
describe('ShoppingCart', () => {
  test('should add item to empty cart successfully', () => {});
  test('should update quantity when adding duplicate item', () => {});
  test('should throw error when adding out-of-stock item', () => {});
  test('should calculate total with tax and shipping', () => {});
});

// Poor test names
describe('Cart', () => {
  test('test1', () => {});
  test('add item', () => {});
  test('works correctly', () => {});
});
```

### 4. Test Data Organization
```yaml
# test-data/cart-scenarios.yaml
scenarios:
  standard_purchase:
    user: 
      type: "registered"
      tier: "standard"
    items:
      - sku: "LAPTOP-001"
        quantity: 1
        price: 999.99
    shipping: "standard"
    payment: "credit_card"
    
  bulk_order:
    user:
      type: "business"
      tier: "premium"
    items:
      - sku: "MOUSE-001"
        quantity: 50
        price: 29.99
    shipping: "express"
    payment: "invoice"
```

## Edge Case Management

### 1. Categorize Edge Cases
```yaml
edge_case_categories:
  boundary_conditions:
    priority: "high"
    examples:
      - "Maximum cart size (100 items)"
      - "Minimum order value ($0.01)"
      - "Maximum single item quantity (99)"
    
  timing_issues:
    priority: "medium"
    examples:
      - "Item goes out of stock during checkout"
      - "Price changes during session"
      - "Session timeout during payment"
    
  data_anomalies:
    priority: "high"
    examples:
      - "Unicode characters in addresses"
      - "Very long product names"
      - "Decimal quantities for digital goods"
    
  concurrent_operations:
    priority: "critical"
    examples:
      - "Multiple devices updating same cart"
      - "Simultaneous checkout attempts"
      - "Race condition on last item"
```

### 2. Edge Case Test Templates
```javascript
// Edge case test template
const edgeCaseTemplate = {
  describe: (category, cases) => {
    describe(`Edge Cases: ${category}`, () => {
      cases.forEach(edgeCase => {
        test(`handles ${edgeCase.description}`, () => {
          // Arrange
          const setup = edgeCase.setup();
          
          // Act
          const result = edgeCase.execute();
          
          // Assert
          expect(result).toMatchObject(edgeCase.expected);
          
          // Verify system stability
          expect(system.isHealthy()).toBe(true);
        });
      });
    });
  }
};
```

### 3. Edge Case Discovery Patterns
```bash
# Systematic edge case discovery
./claude-flow sparc "Find numeric boundary edge cases for all input fields"
./claude-flow sparc "Identify state transition edge cases in order workflow"
./claude-flow sparc "Discover security edge cases in payment processing"
./claude-flow sparc "Find performance edge cases under high load"
```

### 4. Edge Case Documentation
```markdown
## Edge Case: Concurrent Cart Modification

### Description
Two users on different devices modify the same cart simultaneously

### Risk Level
High - Can lead to data inconsistency

### Test Scenario
1. User logs in on Device A and Device B
2. Device A adds Item X to cart
3. Device B adds Item Y to cart (within 100ms)
4. Both devices refresh cart

### Expected Behavior
- Both items appear in cart
- No items are lost
- Quantities are correct
- Last-write-wins for conflicts

### Implementation Notes
- Use optimistic locking
- Implement cart versioning
- Add conflict resolution logic
```

## Test Maintenance

### 1. Regular Test Review Cycles
```yaml
maintenance_schedule:
  daily:
    - Run smoke tests
    - Check for flaky tests
    - Update test data
    
  weekly:
    - Review test coverage metrics
    - Remove obsolete tests
    - Update edge cases
    
  monthly:
    - Full test suite audit
    - Performance optimization
    - Update test documentation
    
  quarterly:
    - Refactor test architecture
    - Update testing strategy
    - Training and knowledge sharing
```

### 2. Test Versioning Strategy
```json
{
  "test_version": "2.1.0",
  "compatible_with": {
    "application": ">=3.0.0",
    "api": "v2",
    "database": ">=10.0"
  },
  "changes": [
    {
      "version": "2.1.0",
      "date": "2024-01-15",
      "changes": [
        "Added payment provider edge cases",
        "Updated cart calculation tests for new tax rules"
      ]
    }
  ]
}
```

### 3. Handling Test Deprecation
```javascript
// Mark tests for deprecation
describe('Legacy Payment Tests', () => {
  beforeAll(() => {
    console.warn('DEPRECATED: These tests will be removed in v3.0.0');
    console.warn('Migration guide: docs/test-migration-v3.md');
  });
  
  test.skip('old payment flow', () => {
    // Test marked for removal
  });
  
  test('new payment flow', () => {
    // Replacement test
  });
});
```

### 4. Test Refactoring Guidelines
```typescript
// Before refactoring
test('user can add item to cart', () => {
  cy.visit('/products');
  cy.get('[data-test="product-1"]').click();
  cy.get('[data-test="add-to-cart"]').click();
  cy.get('[data-test="cart-count"]').should('contain', '1');
});

// After refactoring with Page Objects
test('user can add item to cart', () => {
  productPage.visit();
  productPage.selectProduct('product-1');
  productPage.addToCart();
  cartWidget.assertItemCount(1);
});
```

## Performance Optimization

### 1. Parallel Test Execution
```yaml
parallel_execution:
  strategy: "feature-based"
  max_workers: 5
  distribution:
    - group: "authentication"
      workers: 1
      tests: ["login", "logout", "registration"]
    - group: "cart"
      workers: 2
      tests: ["add", "update", "remove"]
    - group: "checkout"
      workers: 2
      tests: ["payment", "shipping", "confirmation"]
```

### 2. Test Data Optimization
```javascript
// Lazy load test data
class TestDataProvider {
  constructor() {
    this.cache = new Map();
  }
  
  async getTestData(scenario) {
    if (!this.cache.has(scenario)) {
      const data = await this.loadScenarioData(scenario);
      this.cache.set(scenario, data);
    }
    return this.cache.get(scenario);
  }
  
  async loadScenarioData(scenario) {
    // Load only required data
    return await fetch(`/test-data/${scenario}.json`);
  }
}
```

### 3. Smart Test Selection
```python
# Run only affected tests based on code changes
def select_tests_for_changes(changed_files):
    affected_tests = set()
    
    for file in changed_files:
        # Map source files to tests
        if 'cart' in file:
            affected_tests.update(['cart_tests', 'checkout_tests'])
        elif 'payment' in file:
            affected_tests.update(['payment_tests', 'order_tests'])
        elif 'user' in file:
            affected_tests.update(['auth_tests', 'profile_tests'])
    
    return list(affected_tests)

# Usage
changed = git_diff()
tests_to_run = select_tests_for_changes(changed)
run_tests(tests_to_run)
```

### 4. Test Execution Metrics
```json
{
  "execution_metrics": {
    "total_duration": "45 minutes",
    "parallel_savings": "30 minutes",
    "slowest_tests": [
      {
        "name": "E2E checkout flow",
        "duration": "5 minutes",
        "optimization": "Mock external services"
      }
    ],
    "flaky_tests": [
      {
        "name": "Concurrent cart update",
        "failure_rate": "15%",
        "fix": "Add retry logic"
      }
    ]
  }
}
```

## Quality Assurance

### 1. Test Quality Metrics
```yaml
quality_metrics:
  coverage:
    statement: 90%
    branch: 85%
    function: 95%
    requirements: 100%
    
  maintainability:
    duplication: < 5%
    complexity: < 10
    dependencies: minimal
    
  reliability:
    flakiness: < 1%
    false_positives: 0%
    execution_time: stable
```

### 2. Test Review Checklist
```markdown
## Test Review Checklist

### Before Approving Generated Tests

- [ ] **Coverage**: All acceptance criteria covered?
- [ ] **Clarity**: Test names clearly describe behavior?
- [ ] **Independence**: Tests can run in any order?
- [ ] **Repeatability**: Tests produce consistent results?
- [ ] **Performance**: Tests complete in reasonable time?
- [ ] **Data**: Test data is realistic and varied?
- [ ] **Assertions**: Appropriate assertions used?
- [ ] **Error Cases**: Negative scenarios included?
- [ ] **Edge Cases**: Boundary conditions tested?
- [ ] **Cleanup**: Tests clean up after themselves?
```

### 3. Test Documentation Standards
```markdown
## Test Case: Process Refund

### Test ID
TC-PAY-REFUND-001

### Description
Verify that a full refund can be processed for a completed order within 30 days

### Prerequisites
- Order exists in "completed" status
- Order is less than 30 days old
- Payment method supports refunds

### Test Data
```json
{
  "order_id": "ORD-12345",
  "amount": 99.99,
  "payment_method": "credit_card",
  "order_date": "2024-01-01"
}
```

### Steps
1. Navigate to order details page
2. Click "Process Refund" button
3. Select "Full Refund" option
4. Confirm refund action
5. Verify refund status

### Expected Results
- Refund processed successfully
- Order status updated to "refunded"
- Customer receives refund confirmation
- Payment gateway confirms refund
- Inventory updated (if applicable)

### Actual Results
[To be filled during execution]

### Notes
- Partial refunds covered in TC-PAY-REFUND-002
- International refunds may take 5-7 days
```

### 4. Continuous Improvement
```python
# Track and improve test quality over time
class TestQualityTracker:
    def __init__(self):
        self.metrics = {
            'generation_time': [],
            'coverage_achieved': [],
            'bugs_found': [],
            'false_positives': []
        }
    
    def analyze_trends(self):
        return {
            'avg_generation_time': mean(self.metrics['generation_time']),
            'coverage_trend': trend(self.metrics['coverage_achieved']),
            'bug_detection_rate': sum(self.metrics['bugs_found']) / len(self.metrics['bugs_found']),
            'false_positive_rate': sum(self.metrics['false_positives']) / len(self.metrics['false_positives'])
        }
    
    def generate_recommendations(self):
        analysis = self.analyze_trends()
        recommendations = []
        
        if analysis['false_positive_rate'] > 0.05:
            recommendations.append("Review and update test assertions")
        
        if analysis['coverage_trend'] < 0:
            recommendations.append("Increase test generation depth")
        
        return recommendations
```

## Team Collaboration

### 1. Shared Test Conventions
```yaml
# team-conventions.yaml
naming_conventions:
  test_files: "{feature}.spec.{ext}"
  test_suites: "PascalCase"
  test_cases: "should + behavior description"
  
code_style:
  indentation: 2 spaces
  quotes: single
  semicolons: optional
  max_line_length: 100
  
assertion_patterns:
  equality: "expect(actual).toBe(expected)"
  truthiness: "expect(value).toBeTruthy()"
  errors: "expect(() => action()).toThrow()"
  
tags:
  priority: ["@critical", "@high", "@medium", "@low"]
  type: ["@unit", "@integration", "@e2e"]
  status: ["@stable", "@flaky", "@wip"]
```

### 2. Knowledge Sharing
```markdown
## Test Generation Tips & Tricks

### Tip 1: Use Memory for Context
Store frequently used patterns in Claude Flow memory:
```bash
./claude-flow memory store "test_patterns" "Use Page Object Model for UI tests"
```

### Tip 2: Batch Similar Requirements
Generate tests for related features together:
```bash
./claude-flow sparc "Generate tests for all payment-related features"
```

### Tip 3: Create Custom Workflows
Build team-specific workflows:
```bash
cp workflows/prd-to-test-plan.md workflows/team-custom-workflow.md
# Edit to match team needs
```
```

### 3. Code Review Guidelines
```yaml
test_review_criteria:
  must_have:
    - Clear test descriptions
    - Proper assertions
    - Test isolation
    - Error handling
    
  should_have:
    - Performance considerations
    - Reusable components
    - Comprehensive coverage
    - Good documentation
    
  nice_to_have:
    - Visual regression tests
    - Accessibility tests
    - Cross-browser tests
    - Locale-specific tests
```

### 4. Communication Templates
```markdown
## Test Generation Report Template

### Summary
- **Date**: [Generation Date]
- **Triggered By**: [Person/System]
- **Requirements Source**: [Document/User Story]
- **Generation Duration**: [Time]

### Results
- **Total Tests Generated**: [Count]
- **Test Types**: [Unit/Integration/E2E]
- **Coverage Achieved**: [Percentage]
- **Edge Cases Found**: [Count]

### Notable Findings
- [Key insight 1]
- [Key insight 2]

### Action Items
- [ ] Review generated tests
- [ ] Update test data
- [ ] Schedule test execution
- [ ] Update documentation

### Questions/Concerns
- [Any issues or questions]
```

## Anti-Patterns to Avoid

### 1. Over-Generation
❌ **Don't**: Generate tests for every possible permutation
✅ **Do**: Focus on meaningful test scenarios with business value

### 2. Ignoring Maintenance
❌ **Don't**: Generate and forget
✅ **Do**: Regular review and update cycles

### 3. Poor Organization
❌ **Don't**: Dump all tests in one directory
✅ **Do**: Logical feature-based organization

### 4. Missing Context
❌ **Don't**: Generate tests without requirements
✅ **Do**: Provide comprehensive input documentation

### 5. Rigid Test Data
❌ **Don't**: Hardcode test data
✅ **Do**: Use flexible data providers

## Conclusion

Following these best practices will help you:
- Generate high-quality, maintainable tests
- Achieve comprehensive coverage efficiently
- Reduce test maintenance burden
- Improve team collaboration
- Deliver more reliable software

Remember: The Test Case Generator is a tool to augment your testing efforts, not replace human judgment. Always review and refine generated tests to ensure they meet your specific needs and quality standards.