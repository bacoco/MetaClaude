# User Story Templates

## Basic User Story Template

```markdown
**Story ID:** [US-XXX]
**Title:** [Descriptive title]
**Epic:** [Parent epic name]
**Sprint:** [Target sprint]
**Priority:** [High | Medium | Low]
**Story Points:** [Fibonacci number]
**Assignee:** [Team/Person]

### User Story
As a [type of user/persona]
I want [to perform some action/achieve some goal]
So that [I receive some benefit/value]

### Acceptance Criteria
- [ ] [Specific testable criterion 1]
- [ ] [Specific testable criterion 2]
- [ ] [Specific testable criterion 3]

### Dependencies
- [Story ID/System/Component]
- [Story ID/System/Component]

### Notes
[Additional context, assumptions, or clarifications]

### Attachments
- [Mockup/Wireframe links]
- [Technical specification links]
```

---

## Detailed User Story Template (Enterprise)

```markdown
**Story ID:** [US-XXX]
**Title:** [Descriptive title]
**Epic:** [Parent epic name]
**Feature:** [Feature name]
**Theme:** [Strategic theme]
**Sprint:** [Target sprint]
**Release:** [Target release]

### Story Details
**Priority:** [MoSCoW - Must/Should/Could/Won't]
**Business Value:** [1-10]
**Story Points:** [Fibonacci]
**T-Shirt Size:** [XS/S/M/L/XL]
**Risk Level:** [Low/Medium/High]

### User Story Statement
As a [specific persona with context]
I want [detailed action with purpose]
So that [measurable benefit/outcome]

### Detailed Acceptance Criteria
#### Functional Criteria
```gherkin
Given [initial context]
When [action is performed]
Then [expected outcome]
And [additional outcomes]
```

#### Non-Functional Criteria
- **Performance:** [Specific metrics]
- **Security:** [Security requirements]
- **Accessibility:** [WCAG standards]
- **Compatibility:** [Browser/Device requirements]

### User Journey Context
**Entry Point:** [How user gets here]
**Exit Point:** [Where user goes next]
**Alternative Paths:** [Other possible flows]

### Dependencies & Blockers
| Type | Item | Status | Owner |
|------|------|--------|-------|
| Depends On | [Item] | [Status] | [Owner] |
| Blocks | [Item] | [Status] | [Owner] |

### Technical Considerations
- **API Changes:** [Required endpoints]
- **Database Impact:** [Schema changes]
- **Performance Impact:** [Expected impact]
- **Security Considerations:** [Security notes]

### Business Rules
1. [Business rule 1]
2. [Business rule 2]
3. [Business rule 3]

### Test Scenarios
- **Happy Path:** [Primary success scenario]
- **Edge Cases:** [Boundary conditions]
- **Error Cases:** [Failure scenarios]

### Design Assets
- **Mockups:** [Link]
- **Prototypes:** [Link]
- **Style Guide:** [Link]

### Definition of Done
- [ ] Code complete and peer reviewed
- [ ] Unit tests written and passing
- [ ] Integration tests passing
- [ ] Documentation updated
- [ ] Accessibility tested
- [ ] Performance tested
- [ ] Security reviewed
- [ ] Deployed to staging
- [ ] Product owner accepted

### Notes & Assumptions
- **Assumptions:** [List assumptions]
- **Out of Scope:** [What's not included]
- **Future Considerations:** [Future enhancements]
```

---

## Technical Story Template

```markdown
**Story ID:** [TS-XXX]
**Title:** [Technical improvement/debt]
**Component:** [System component]
**Sprint:** [Target sprint]
**Priority:** [High | Medium | Low]
**Story Points:** [Fibonacci number]

### Technical Story
As a [system/component]
I need [technical capability/improvement]
So that [system benefit/quality improvement]

### Technical Acceptance Criteria
- [ ] [Technical specification 1]
- [ ] [Performance benchmark]
- [ ] [Security requirement]
- [ ] [Code quality metric]

### Technical Details
**Current State:** [Description]
**Target State:** [Description]
**Migration Path:** [Steps required]

### Impact Analysis
- **Performance Impact:** [Positive/Negative/Neutral]
- **Security Impact:** [Description]
- **Maintenance Impact:** [Description]

### Dependencies
- [Technical dependency 1]
- [Technical dependency 2]

### Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|---------|------------|
| [Risk] | [H/M/L] | [H/M/L] | [Plan] |
```

---

## Bug Fix Story Template

```markdown
**Story ID:** [BUG-XXX]
**Title:** [Bug description]
**Severity:** [Critical | High | Medium | Low]
**Priority:** [P1 | P2 | P3 | P4]
**Affected Version:** [Version]
**Reporter:** [Name]
**Assignee:** [Name]

### Bug Description
As a [affected user type]
I want [the bug to be fixed]
So that [I can perform intended action correctly]

### Current Behavior
[Detailed description of what's happening]

### Expected Behavior
[Detailed description of what should happen]

### Reproduction Steps
1. [Step 1 with specific details]
2. [Step 2 with specific details]
3. [Step 3 with specific details]
4. [Observe incorrect behavior]

### Environment
- **Browser/App:** [Version]
- **OS:** [Version]
- **Device:** [Type]
- **User Role:** [Role]

### Acceptance Criteria
- [ ] Bug no longer reproducible
- [ ] Expected behavior verified
- [ ] No regression in related features
- [ ] Fix verified in affected environments

### Root Cause
[Technical explanation once identified]

### Fix Approach
[Description of the fix]

### Test Coverage
- [ ] Unit test added
- [ ] Integration test added
- [ ] Regression test added
```

---

## Spike Story Template

```markdown
**Story ID:** [SPIKE-XXX]
**Title:** [Research/Investigation topic]
**Type:** [Research | Prototype | Investigation]
**Timebox:** [Hours/Days]
**Sprint:** [Target sprint]

### Spike Story
As a [team/role]
I need to [investigate/research/prototype]
So that [we can make informed decision about]

### Research Questions
1. [Specific question 1]
2. [Specific question 2]
3. [Specific question 3]

### Success Criteria
- [ ] Questions answered with evidence
- [ ] Recommendations documented
- [ ] Findings presented to team
- [ ] Decision made on next steps

### Deliverables
- [ ] Research document
- [ ] Proof of concept (if applicable)
- [ ] Recommendation report
- [ ] Presentation to stakeholders

### Constraints
- **Time limit:** [Duration]
- **Budget:** [If applicable]
- **Scope:** [Boundaries]
```

---

## Epic Template

```markdown
**Epic ID:** [EPIC-XXX]
**Title:** [Epic name]
**Theme:** [Strategic theme]
**Owner:** [Product owner]
**Target Release:** [Release]
**Status:** [Discovery | Ready | In Progress | Done]

### Epic Description
[High-level description of the epic's purpose and value]

### Business Objective
[Clear statement of business goal this epic achieves]

### Success Metrics
| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| [KPI 1] | [Value] | [Value] | [Method] |
| [KPI 2] | [Value] | [Value] | [Method] |

### User Stories Summary
| Story | Points | Priority | Status |
|-------|--------|----------|--------|
| [US-001] | [Pts] | [Pri] | [Status] |
| [US-002] | [Pts] | [Pri] | [Status] |

### Dependencies
- **Depends On:** [Other epics/systems]
- **Depended By:** [Other epics/systems]

### Risks & Mitigation
| Risk | Impact | Mitigation |
|------|---------|------------|
| [Risk] | [Impact] | [Plan] |

### Timeline
- **Start Date:** [Date]
- **Target Date:** [Date]
- **Milestones:**
  - [Milestone 1]: [Date]
  - [Milestone 2]: [Date]
```

---

## Quick Story Templates

### Feature Story
```markdown
As a [user]
I want [feature]
So that [benefit]

AC:
- Works as described
- Handles errors gracefully
- Meets performance requirements
```

### Performance Story
```markdown
As a [user]
I want [action to be faster]
So that [improved experience]

AC:
- Response time < [X] seconds
- Handles [Y] concurrent users
- No degradation under load
```

### Security Story
```markdown
As a [user/system]
I want [security feature]
So that [protection achieved]

AC:
- Passes security scan
- Meets compliance requirements
- No vulnerabilities introduced
```

### UX Improvement Story
```markdown
As a [user]
I want [improved experience]
So that [easier/better usage]

AC:
- Usability tested with [N] users
- Accessibility standards met
- Positive feedback received
```

---

## Story Writing Best Practices

### INVEST Criteria Checklist
- **I**ndependent: Can be developed separately
- **N**egotiable: Details can be discussed
- **V**aluable: Provides clear value
- **E**stimable: Can be sized
- **S**mall: Fits in a sprint
- **T**estable: Has clear acceptance criteria

### Common Formats

#### Connextra Format (Recommended)
```
As a [persona]
I want [what]
So that [why]
```

#### Job Story Format
```
When [situation]
I want [motivation]
So I can [expected outcome]
```

#### Feature Injection Format
```
In order to [achieve value]
As a [persona]
I want [feature]
```

### Tips for Writing Great Stories
1. Focus on the user's perspective
2. Describe the "what" not the "how"
3. Include the "why" for context
4. Keep stories small and focused
5. Make acceptance criteria specific and measurable
6. Consider edge cases and error scenarios
7. Include non-functional requirements
8. Link to relevant documentation
9. Add visual aids when helpful
10. Review with the team before finalizing