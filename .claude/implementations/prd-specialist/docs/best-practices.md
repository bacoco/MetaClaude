# PRD Specialist Best Practices

## Overview
This document outlines best practices for creating effective Product Requirements Documents, user stories, and acceptance criteria that drive successful product development.

---

## 1. Requirements Gathering Best Practices

### Start with Why
- **Understand the Problem**: Before defining solutions, deeply understand the problem
- **Business Objectives**: Link all requirements to clear business goals
- **User Needs**: Base requirements on validated user research
- **Success Metrics**: Define measurable outcomes upfront

### Stakeholder Engagement
```markdown
✅ DO:
- Identify ALL stakeholders early
- Schedule regular check-ins
- Use their language, not technical jargon
- Document all decisions and rationales
- Get written approval for key decisions

❌ DON'T:
- Assume stakeholder availability
- Skip "minor" stakeholders
- Make decisions in isolation
- Rely on verbal agreements
- Surprise stakeholders late in the process
```

### Comprehensive Collection
1. **Multiple Sources**
   - User interviews
   - Analytics data
   - Support tickets
   - Competitive analysis
   - Technical constraints

2. **Validation Techniques**
   - Cross-reference sources
   - Prototype testing
   - Stakeholder reviews
   - Technical feasibility checks
   - User acceptance testing

3. **Documentation Standards**
   - Use consistent templates
   - Maintain traceability
   - Version control everything
   - Include context and rationale
   - Regular updates and reviews

---

## 2. Writing Effective PRDs

### Structure and Organization

#### Executive Summary Excellence
```markdown
GOOD Executive Summary:
"This PRD outlines a mobile payment feature that will:
- Increase checkout conversion by 25%
- Reduce cart abandonment from 68% to 45%
- Generate $2M additional revenue annually
- Launch in Q3 2024 with phased rollout"

POOR Executive Summary:
"This document describes a new payment feature 
that will make checkout easier for users."
```

#### Clear Problem Statements
```markdown
Effective Problem Statement Structure:
1. Current State (with data)
2. Pain Points (specific examples)
3. Impact (quantified where possible)
4. Opportunity (clear value proposition)

Example:
"Currently, 68% of users abandon cart at payment (analytics data).
User research shows 45% cite 'too many steps' as primary reason.
This results in $5M lost revenue annually.
Streamlining to one-click checkout could recover 40% of lost sales."
```

### Requirements Clarity

#### Functional Requirements
```markdown
✅ GOOD: Specific and Measurable
"The system shall send password reset email within 
30 seconds of request, containing a unique link 
valid for 24 hours."

❌ POOR: Vague and Untestable
"The system should handle password resets quickly 
and securely."
```

#### Non-Functional Requirements
```markdown
Performance:
- Response time: 95th percentile < 2 seconds
- Throughput: 10,000 transactions per minute
- Availability: 99.9% uptime excluding maintenance

NOT:
- "System should be fast"
- "Must handle high load"
- "Should rarely go down"
```

### Visual Communication
- **Use Diagrams**: Flowcharts, wireframes, architecture diagrams
- **Include Examples**: Show actual scenarios and use cases
- **Create Matrices**: For complex relationships or decisions
- **Add Screenshots**: For existing systems or competitors

---

## 3. User Story Excellence

### Story Writing Principles

#### Focus on Value
```markdown
✅ Value-Focused Story:
"As a frequent shopper
I want to save my payment methods
So that I can checkout in under 30 seconds"

❌ Feature-Focused Story:
"As a user
I want a save payment button
So that the button saves payment"
```

#### Right-Sizing Stories
```markdown
Too Large (Epic):
"As a user, I want a complete shopping experience"

Right-Sized (Story):
"As a shopper, I want to filter products by price range"

Too Small (Task):
"As a developer, I want to add a button CSS class"
```

### INVEST Criteria Application

#### Independent
- Can be developed in any sequence
- Minimal dependencies on other stories
- Self-contained value delivery

#### Negotiable
- Details can be discussed
- Implementation flexible
- Open to creative solutions

#### Valuable
- Clear benefit to users or business
- Measurable impact
- Worth the investment

#### Estimable
- Team can size it
- Scope is clear
- Risks identified

#### Small
- Fits in one sprint
- Single focused outcome
- Incremental value

#### Testable
- Clear acceptance criteria
- Definite done state
- Measurable results

### Story Splitting Patterns

#### Workflow Steps
```markdown
Original: "User completes purchase"
Split by workflow:
1. "User adds items to cart"
2. "User enters shipping info"
3. "User completes payment"
4. "User receives confirmation"
```

#### Business Rules
```markdown
Original: "Apply discounts at checkout"
Split by rules:
1. "Apply percentage discounts"
2. "Apply fixed amount discounts"
3. "Apply BOGO offers"
4. "Stack multiple discounts"
```

#### Data Types
```markdown
Original: "Search all content"
Split by data:
1. "Search products"
2. "Search categories"
3. "Search help articles"
4. "Search user reviews"
```

---

## 4. Acceptance Criteria Mastery

### Characteristics of Good Criteria

#### Specific and Measurable
```markdown
✅ GOOD:
- Response time < 2 seconds for 95% of requests
- Error rate < 0.1% in production
- All form fields validate on blur

❌ POOR:
- Should be fast
- Minimal errors
- Good validation
```

#### Complete Coverage
- **Happy Path**: Primary success scenario
- **Edge Cases**: Boundary conditions
- **Error Cases**: Failure scenarios
- **Non-Functional**: Performance, security, accessibility

### Writing Techniques

#### Scenario-Based Approach
```gherkin
Given a registered user with saved addresses
When they proceed to checkout
Then shipping address dropdown shows saved addresses
And the most recent address is pre-selected
But they can still enter a new address
```

#### Checklist Approach
```markdown
Payment Processing:
- [ ] Accepts Visa, Mastercard, Amex
- [ ] Validates card number format
- [ ] Checks expiration date is future
- [ ] Processes payment within 5 seconds
- [ ] Shows clear error for declined cards
- [ ] Logs all transactions for audit
```

---

## 5. Stakeholder Alignment

### Communication Strategies

#### Know Your Audience
```markdown
For Executives:
- Focus on ROI and strategic impact
- Use visual dashboards
- Highlight key metrics
- Keep it concise

For Developers:
- Include technical details
- Provide clear specifications
- Address implementation concerns
- Include API documentation

For Users:
- Use their language
- Focus on benefits
- Include mockups
- Describe workflows
```

### Conflict Resolution

#### Priority Negotiation Framework
1. **Data-Driven Decisions**
   - Use analytics to support positions
   - Calculate ROI for each option
   - Consider technical debt impact

2. **Win-Win Solutions**
   - Find common ground
   - Propose creative alternatives
   - Phase features if needed

3. **Clear Escalation**
   - Define decision rights
   - Document disagreements
   - Set escalation timelines

### Change Management

#### Change Request Process
```markdown
1. Document the Request
   - What is changing
   - Why it's needed
   - Impact analysis
   - Effort estimate

2. Evaluate Impact
   - Timeline effect
   - Budget implications
   - Risk assessment
   - Resource needs

3. Get Approval
   - Stakeholder sign-off
   - Updated documentation
   - Communication plan
   - Implementation approach
```

---

## 6. Quality Assurance

### PRD Review Checklist

#### Completeness
- [ ] All sections filled
- [ ] Requirements traced to objectives
- [ ] Success metrics defined
- [ ] Risks identified
- [ ] Dependencies mapped

#### Clarity
- [ ] Unambiguous language
- [ ] Technical terms defined
- [ ] Examples provided
- [ ] Visuals included
- [ ] Consistent terminology

#### Feasibility
- [ ] Technical review complete
- [ ] Resource availability confirmed
- [ ] Timeline realistic
- [ ] Budget approved
- [ ] Risks acceptable

### Continuous Improvement

#### Retrospective Questions
1. What requirements were missed?
2. Which stories needed most refinement?
3. What caused delays or rework?
4. How accurate were estimates?
5. What can we improve next time?

#### Metrics to Track
- Requirement stability (changes after approval)
- Story acceptance rate (first attempt)
- Estimate accuracy (actual vs planned)
- Defect origin (requirements vs implementation)
- Stakeholder satisfaction scores

---

## 7. Tool Usage Best Practices

### Integration Excellence
- **Single Source of Truth**: One system for requirements
- **Automatic Sync**: Keep tools synchronized
- **Version Control**: Track all changes
- **Access Control**: Right people, right permissions
- **Audit Trail**: Who changed what when

### Collaboration Tools
```markdown
Recommended Stack:
- Requirements: Jira/Azure DevOps
- Documentation: Confluence/Notion
- Communication: Slack/Teams
- Mockups: Figma/Sketch
- Analytics: Mixpanel/Amplitude
```

---

## 8. Common Pitfalls and Solutions

### Pitfall: Analysis Paralysis
**Solution**: Time-box research phases, embrace iterative refinement

### Pitfall: Assumption-Based Requirements
**Solution**: Validate with data, prototype early, test with users

### Pitfall: Over-Engineering
**Solution**: Start with MVP, build incrementally, measure impact

### Pitfall: Poor Stakeholder Engagement
**Solution**: Regular check-ins, clear communication plans, defined RACI

### Pitfall: Scope Creep
**Solution**: Strong change control, clear project boundaries, phase features

---

## 9. Templates and Checklists

### Quick Reference Checklists

#### New Feature Checklist
- [ ] Problem validated with data
- [ ] Solution prototyped/tested
- [ ] Requirements documented
- [ ] Stories created and sized
- [ ] Acceptance criteria defined
- [ ] Technical feasibility confirmed
- [ ] Resources allocated
- [ ] Timeline established
- [ ] Risks identified
- [ ] Success metrics defined

#### Story Ready Checklist
- [ ] Follows story format
- [ ] INVEST criteria met
- [ ] Acceptance criteria complete
- [ ] Dependencies identified
- [ ] Sized by team
- [ ] Priority assigned
- [ ] Technical notes added
- [ ] Mockups attached

---

## 10. Scaling Best Practices

### For Large Teams
- Establish clear roles and responsibilities
- Create requirement templates and standards
- Implement review and approval workflows
- Use automation for repetitive tasks
- Regular training and knowledge sharing

### For Complex Products
- Modular requirement structure
- Clear interface definitions
- Comprehensive dependency mapping
- Phased delivery approach
- Robust change management

### For Fast-Moving Environments
- Lightweight documentation
- Frequent stakeholder sync
- Automated testing focus
- Continuous deployment ready
- Rapid feedback loops