# Acceptance Criteria Templates

## Overview
This document provides comprehensive templates for writing clear, testable acceptance criteria using various formats and patterns suitable for different types of requirements.

---

## Given-When-Then (Gherkin) Format

### Basic Template
```gherkin
Given [initial context or precondition]
When [action performed by the user]
Then [expected outcome or result]
```

### Extended Template with Multiple Conditions
```gherkin
Given [initial context]
  And [additional context]
  And [more context if needed]
When [primary action]
  And [secondary action]
Then [primary expected outcome]
  And [additional outcome]
  But [negative outcome that should NOT happen]
```

### Examples

#### User Authentication
```gherkin
Feature: User Login

Scenario: Successful login with valid credentials
  Given I am on the login page
    And I have a registered account
  When I enter valid username "user@example.com"
    And I enter valid password "SecurePass123"
    And I click the "Login" button
  Then I should be redirected to the dashboard
    And I should see "Welcome back" message
    And my session should be active for 24 hours

Scenario: Failed login with invalid credentials
  Given I am on the login page
  When I enter invalid credentials
  Then I should see error message "Invalid username or password"
    And I should remain on the login page
    And the login attempt should be logged
```

#### E-commerce Checkout
```gherkin
Feature: Shopping Cart Checkout

Scenario: Successful checkout with saved payment method
  Given I have items in my shopping cart
    And I am a logged-in user
    And I have a saved payment method
  When I proceed to checkout
    And I confirm my shipping address
    And I select my saved credit card
    And I click "Place Order"
  Then my order should be created with a unique order ID
    And my payment should be processed
    And I should receive an order confirmation email within 5 minutes
    And the inventory should be updated
    And I should see the order in my order history
```

---

## Rule-Based Format

### Template
```markdown
### Business Rules for [Feature Name]

1. **Rule Name**: [Description]
   - Condition: [When this applies]
   - Action: [What happens]
   - Exception: [Any exceptions]

2. **Rule Name**: [Description]
   - Condition: [When this applies]
   - Action: [What happens]
   - Exception: [Any exceptions]
```

### Examples

#### Password Requirements
```markdown
### Business Rules for Password Creation

1. **Password Complexity**: Passwords must meet security standards
   - Minimum 8 characters
   - At least one uppercase letter (A-Z)
   - At least one lowercase letter (a-z)
   - At least one number (0-9)
   - At least one special character (!@#$%^&*)
   - Cannot contain username or email

2. **Password History**: Prevent password reuse
   - Cannot match last 5 passwords
   - Must be different from current password
   - Comparison is case-sensitive

3. **Password Expiration**: Enforce regular updates
   - Passwords expire after 90 days
   - Warning shown 14 days before expiration
   - Grace period of 7 days after expiration
   - Account locked after grace period
```

#### Order Processing
```markdown
### Business Rules for Order Processing

1. **Order Validation**: All orders must be valid
   - All items must be in stock
   - Shipping address must be complete
   - Payment method must be valid
   - Total must be greater than $0

2. **Inventory Management**: Stock must be managed
   - Reserved when added to cart (15 min hold)
   - Deducted upon successful payment
   - Released if payment fails
   - Backordered if stock depleted during checkout

3. **Payment Processing**: Payments must be secure
   - Pre-authorization before order confirmation
   - Full charge after order confirmation
   - Automatic retry for soft declines (max 3)
   - Refund initiated within 24 hours of cancellation
```

---

## Checklist Format

### Simple Checklist Template
```markdown
### Acceptance Criteria for [Feature]

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] [Performance requirement]
- [ ] [Security requirement]
- [ ] [Error handling requirement]
```

### Detailed Checklist Template
```markdown
### Acceptance Criteria for [Feature]

#### Functional Requirements
- [ ] [Primary function works as expected]
- [ ] [Secondary function works correctly]
- [ ] [Edge case 1 is handled]
- [ ] [Edge case 2 is handled]

#### User Interface
- [ ] [UI element 1 displays correctly]
- [ ] [UI element 2 responds to interaction]
- [ ] [Responsive on mobile devices]
- [ ] [Accessible via keyboard navigation]

#### Performance
- [ ] [Page loads in < 3 seconds]
- [ ] [API responds in < 500ms]
- [ ] [Can handle 100 concurrent users]

#### Security
- [ ] [Input validation prevents XSS]
- [ ] [Authentication required for protected resources]
- [ ] [Data encrypted in transit]

#### Error Handling
- [ ] [Graceful handling of network errors]
- [ ] [User-friendly error messages]
- [ ] [Errors logged for debugging]
```

### Examples

#### User Registration Form
```markdown
### Acceptance Criteria for User Registration

#### Form Validation
- [ ] Email field validates email format
- [ ] Email uniqueness checked in real-time
- [ ] Password strength indicator shows
- [ ] Passwords match confirmation field
- [ ] All required fields marked with asterisk
- [ ] Form cannot submit with errors

#### Submission Process
- [ ] Submit button disabled during processing
- [ ] Loading indicator shown during submission
- [ ] Success message displayed after registration
- [ ] User automatically logged in after registration
- [ ] Welcome email sent within 5 minutes

#### Error Handling
- [ ] Field-level error messages show on blur
- [ ] Summary error message shows on submit
- [ ] Server errors display user-friendly message
- [ ] Form data preserved on error
- [ ] Maximum 5 registration attempts per hour

#### Accessibility
- [ ] All form fields have labels
- [ ] Error messages announced by screen readers
- [ ] Tab order is logical
- [ ] Submit with Enter key works
- [ ] Color not sole indicator of error
```

---

## Scenario Table Format

### Template
```markdown
| Scenario | Input/Action | Expected Result | Error Handling |
|----------|--------------|-----------------|----------------|
| [Scenario 1] | [Input] | [Output] | [Error behavior] |
| [Scenario 2] | [Input] | [Output] | [Error behavior] |
```

### Examples

#### Search Functionality
```markdown
### Search Feature Acceptance Criteria

| Scenario | Search Query | Expected Results | Error Handling |
|----------|--------------|------------------|----------------|
| Exact match | "iPhone 13" | Exact matches first, related items below | N/A |
| Partial match | "iPho" | Suggest "iPhone" products | Show suggestions dropdown |
| No results | "xyz123abc" | "No results found" message | Suggest similar items |
| Special characters | "iPhone@#$" | Strip special chars, search "iPhone" | Clean input silently |
| Empty search | "" | Show popular products | "Enter search term" hint |
| Long query | >100 chars | Truncate to 100 chars | Show truncation message |
| SQL injection | "'; DROP TABLE" | Sanitized, treated as text | Log security attempt |
```

#### File Upload
```markdown
### File Upload Acceptance Criteria

| File Type | Size | Expected Result | Error Message |
|-----------|------|-----------------|---------------|
| JPG | < 5MB | Upload successful | N/A |
| PNG | < 5MB | Upload successful | N/A |
| PDF | < 10MB | Upload successful | N/A |
| JPG | > 5MB | Upload rejected | "File too large. Max 5MB for images" |
| EXE | Any | Upload rejected | "File type not allowed" |
| No file | N/A | Button disabled | "Please select a file" |
| Multiple | < 20MB total | All processed | Progress for each file |
```

---

## State Transition Format

### Template
```markdown
### State Transitions for [Feature]

| Current State | Action | Next State | Conditions |
|---------------|--------|------------|------------|
| [State A] | [Action 1] | [State B] | [Conditions] |
| [State A] | [Action 2] | [State C] | [Conditions] |
```

### Example: Order Status
```markdown
### Order Status Transitions

| Current State | Action | Next State | Conditions |
|---------------|--------|------------|------------|
| Draft | Submit | Pending | All required fields complete |
| Pending | Process Payment | Processing | Valid payment method |
| Processing | Payment Success | Confirmed | Payment authorized |
| Processing | Payment Failed | Payment Failed | Payment declined |
| Confirmed | Ship | Shipped | Tracking number assigned |
| Shipped | Deliver | Delivered | Delivery confirmed |
| Any State | Cancel | Cancelled | Within cancellation window |

### Additional Rules:
- Orders cannot move backwards in status (except to Cancelled)
- Each transition must be logged with timestamp
- Email notifications sent for each status change
- Status changes must be atomic transactions
```

---

## Performance Criteria Format

### Template
```markdown
### Performance Acceptance Criteria

| Metric | Threshold | Measurement Method | Frequency |
|--------|-----------|-------------------|-----------|
| [Metric] | [Value] | [How to measure] | [When] |
```

### Example: API Performance
```markdown
### API Performance Criteria

| Metric | Threshold | Measurement Method | Frequency |
|--------|-----------|-------------------|-----------|
| Response Time (p95) | < 500ms | APM tool monitoring | Continuous |
| Response Time (p99) | < 1000ms | APM tool monitoring | Continuous |
| Throughput | > 1000 req/sec | Load testing | Pre-release |
| Error Rate | < 0.1% | Error tracking | Continuous |
| Availability | > 99.9% | Uptime monitoring | Monthly |
| CPU Usage | < 70% | Server monitoring | Continuous |
| Memory Usage | < 80% | Server monitoring | Continuous |

### Load Test Scenarios:
1. Normal Load: 500 concurrent users
2. Peak Load: 2000 concurrent users  
3. Stress Test: Increase until failure
4. Soak Test: 1000 users for 4 hours
```

---

## Accessibility Criteria Format

### Template
```markdown
### Accessibility Acceptance Criteria

WCAG 2.1 Level [A/AA/AAA] Compliance

#### Perceivable
- [ ] [Criterion]

#### Operable
- [ ] [Criterion]

#### Understandable
- [ ] [Criterion]

#### Robust
- [ ] [Criterion]
```

### Example: Form Accessibility
```markdown
### Form Accessibility Criteria

WCAG 2.1 Level AA Compliance Required

#### Perceivable
- [ ] All images have alt text
- [ ] Color contrast ratio ≥ 4.5:1 for normal text
- [ ] Color contrast ratio ≥ 3:1 for large text
- [ ] Error messages not indicated by color alone
- [ ] Form instructions available to screen readers

#### Operable
- [ ] All functions keyboard accessible
- [ ] Tab order follows visual flow
- [ ] No keyboard traps
- [ ] Skip links provided
- [ ] Sufficient time limits (adjustable)

#### Understandable
- [ ] Labels clearly describe fields
- [ ] Error messages are specific and helpful
- [ ] Required fields clearly marked
- [ ] Instructions provided before form
- [ ] Consistent navigation throughout

#### Robust
- [ ] Valid HTML markup
- [ ] ARIA labels where needed
- [ ] Compatible with major screen readers
- [ ] Works without JavaScript
- [ ] Progressive enhancement applied
```

---

## Mobile-Specific Criteria

### Template
```markdown
### Mobile Acceptance Criteria

#### iOS
- [ ] [iOS-specific criterion]

#### Android  
- [ ] [Android-specific criterion]

#### Both Platforms
- [ ] [Common criterion]
```

### Example: Mobile App Feature
```markdown
### Mobile Push Notifications

#### iOS Requirements
- [ ] Request permission on first launch
- [ ] Deep link to relevant content
- [ ] Badge count updates correctly
- [ ] Respect notification settings
- [ ] Work in background/foreground
- [ ] Rich notifications with images

#### Android Requirements
- [ ] Create notification channel
- [ ] Support notification actions
- [ ] Respect Do Not Disturb
- [ ] Work with battery optimization
- [ ] Handle notification grouping
- [ ] Support custom sounds

#### Both Platforms
- [ ] Deliver within 30 seconds
- [ ] Track delivery/open rates
- [ ] Support localization
- [ ] Graceful offline handling
- [ ] A/B testing capability
- [ ] Analytics integration
```

---

## Best Practices for Writing Acceptance Criteria

### DO's
1. **Be Specific**: Use concrete values, not vague terms
   - ❌ "Fast loading"
   - ✅ "Loads within 2 seconds on 3G"

2. **Be Measurable**: Include how to verify
   - ❌ "User-friendly interface"
   - ✅ "Users complete task in <3 clicks"

3. **Be Testable**: Anyone should be able to verify
   - ❌ "Works well"
   - ✅ "Passes all 15 test scenarios"

4. **Include Edge Cases**: Think beyond happy path
   - Empty states
   - Maximum values
   - Network failures
   - Concurrent actions

5. **Consider Non-Functional Requirements**
   - Performance
   - Security
   - Accessibility
   - Compatibility

### DON'Ts
1. **Don't Include Implementation Details**
   - ❌ "Use React hooks for state"
   - ✅ "State persists across sessions"

2. **Don't Be Ambiguous**
   - ❌ "Appropriate error handling"
   - ✅ "Show specific error for each field"

3. **Don't Forget Context**
   - ❌ "Button works"
   - ✅ "Submit button enabled when form valid"

4. **Don't Mix Criteria**
   - Keep functional and non-functional separate
   - Group related criteria together

5. **Don't Assume Knowledge**
   - Define technical terms
   - Provide examples where helpful