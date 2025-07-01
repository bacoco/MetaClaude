# Test Case Template

## Test Case Information

**Test Case ID**: TC-[FEATURE]-[NUMBER]  
**Test Case Title**: [Clear, descriptive title]  
**Priority**: [Critical | High | Medium | Low]  
**Type**: [Functional | Integration | E2E | Performance | Security | Usability]  
**Automated**: [Yes | No | Partial]  

## Test Objective
[Brief description of what this test case validates]

## Prerequisites/Preconditions
- [ ] [Condition 1]
- [ ] [Condition 2]
- [ ] [Condition 3]

## Test Data
```yaml
# Required test data
user:
  email: "test@example.com"
  role: "standard"
  
product:
  sku: "PROD-001"
  quantity: 2
  
environment:
  url: "https://test.example.com"
  browser: "Chrome latest"
```

## Test Steps

| Step | Action | Expected Result | Actual Result | Pass/Fail |
|------|--------|-----------------|---------------|-----------|
| 1    | [Action description] | [Expected outcome] | [To be filled] | [To be filled] |
| 2    | [Action description] | [Expected outcome] | [To be filled] | [To be filled] |
| 3    | [Action description] | [Expected outcome] | [To be filled] | [To be filled] |

## Post-Conditions
- [ ] [State after test execution]
- [ ] [Cleanup required]

## Notes
- [Any additional information]
- [Known issues or limitations]
- [Related test cases]

## Attachments
- [Screenshots]
- [Logs]
- [Test data files]

---
**Created Date**: [Date]  
**Last Modified**: [Date]  
**Author**: [Name]  
**Version**: [1.0]