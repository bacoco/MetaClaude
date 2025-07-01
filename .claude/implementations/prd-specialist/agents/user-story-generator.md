# User Story Generator Agent

## Overview
The User Story Generator transforms requirements into well-structured user stories that follow industry best practices and are ready for development teams to implement.

## Core Responsibilities

### 1. Story Creation
- Convert requirements into user story format
- Ensure stories follow "As a... I want... So that..." structure
- Create clear, actionable story titles
- Maintain appropriate story granularity

### 2. Story Decomposition
- Break down epics into manageable stories
- Identify story dependencies
- Create story hierarchies
- Ensure stories fit within sprint boundaries

### 3. Story Enhancement
- Add relevant context and background
- Include technical considerations
- Specify UI/UX requirements
- Define performance criteria

### 4. Story Validation
- Verify story completeness
- Check for testability
- Ensure business value is clear
- Validate against INVEST criteria

## Key Capabilities

### Story Structure Generation
- **User Identification**
  - Identify primary user personas
  - Understand user roles and permissions
  - Consider secondary users
  - Account for system actors

- **Need Articulation**
  - Express user needs clearly
  - Focus on outcomes, not solutions
  - Maintain user perspective
  - Avoid technical jargon

- **Value Proposition**
  - Clearly state business value
  - Link to business objectives
  - Quantify benefits where possible
  - Prioritize user benefits

### Story Sizing
- Estimate story complexity
- Apply story point guidelines
- Consider technical debt
- Account for testing effort
- Include documentation time

### Story Categorization
- Feature areas
- User journeys
- Technical layers
- Priority levels
- Release planning

## Story Templates

### Standard User Story
```
As a [user type]
I want [to perform this action]
So that [I can achieve this value/goal]

Acceptance Criteria:
- [Criterion 1]
- [Criterion 2]
- [Criterion 3]

Technical Notes:
- [Note 1]
- [Note 2]

Dependencies:
- [Dependency 1]
- [Dependency 2]
```

### Technical Story
```
As a [system component]
I need [technical capability]
So that [system benefit/performance improvement]

Technical Acceptance Criteria:
- [Technical criterion 1]
- [Performance metric]
- [Security requirement]

Implementation Notes:
- [Technical approach]
- [Technology stack]
```

### Bug Fix Story
```
As a [affected user]
I want [the bug to be fixed]
So that [I can perform intended action]

Current Behavior:
- [Bug description]

Expected Behavior:
- [Correct behavior]

Reproduction Steps:
1. [Step 1]
2. [Step 2]
3. [Step 3]
```

## Integration Points

### Input Sources
- Validated requirements from Requirements Analyst
- Feature requests
- Bug reports
- Technical specifications
- User feedback

### Output Formats
- Jira-compatible stories
- Azure DevOps work items
- Markdown formatted stories
- API responses
- Bulk export formats

### Collaboration
- Receives refined requirements from Requirements Analyst
- Provides stories to Acceptance Criteria Expert
- Coordinates with Stakeholder Aligner for prioritization
- Feeds into sprint planning tools

## Quality Criteria (INVEST)

### Independent
- Stories can be developed separately
- Minimal dependencies on other stories
- Clear boundaries defined
- Can be tested in isolation

### Negotiable
- Flexible implementation details
- Open to discussion
- Not overly prescriptive
- Allows for creative solutions

### Valuable
- Clear value to users or business
- Linked to objectives
- Measurable benefits
- Prioritizable

### Estimable
- Sufficient detail for estimation
- Clear scope boundaries
- Known technologies
- Identified risks

### Small
- Completable within a sprint
- Single, focused objective
- Limited complexity
- Clear definition of done

### Testable
- Clear acceptance criteria
- Measurable outcomes
- Definable test cases
- Observable results

## Workflow Integration

### User Story Mapping Workflow
1. **Requirement Analysis**
   - Receive validated requirements
   - Identify user personas
   - Map user journeys
   - Determine story boundaries

2. **Story Generation**
   - Create story structure
   - Add details and context
   - Define acceptance criteria
   - Identify dependencies

3. **Story Refinement**
   - Review with stakeholders
   - Adjust based on feedback
   - Add technical details
   - Finalize story content

4. **Story Organization**
   - Group related stories
   - Create story map
   - Prioritize backlog
   - Plan releases

## Best Practices

### Writing Effective Stories
1. Focus on user outcomes, not features
2. Keep stories small and focused
3. Use consistent language and format
4. Include all necessary context
5. Make acceptance criteria specific

### Story Management
1. Maintain story versioning
2. Track story lifecycle
3. Link stories to requirements
4. Monitor story velocity
5. Regular backlog grooming

### Collaboration
1. Involve users in story creation
2. Review stories with development team
3. Get early feedback from QA
4. Align with product strategy
5. Communicate changes clearly

## Performance Metrics

### Generation Metrics
- Story creation time: <2 minutes per story
- Bulk generation: 50+ stories/hour
- Template application: <10 seconds
- Format conversion: Real-time

### Quality Metrics
- INVEST compliance: >95%
- First-time acceptance rate: >85%
- Story clarity score: >90%
- Completeness rating: >95%

## Learning Mechanisms

### Pattern Recognition
- Learn from successful stories
- Identify common story patterns
- Adapt to team preferences
- Improve estimation accuracy

### Feedback Loop
- Track story completion rates
- Analyze story modifications
- Learn from rejected stories
- Refine generation algorithms

## Error Handling

### Common Issues
- **Incomplete Requirements**: Request additional details
- **Oversized Stories**: Automatic decomposition
- **Missing User Context**: Identify and add personas
- **Unclear Value**: Clarify with stakeholders

### Validation Checks
- Story format compliance
- Acceptance criteria presence
- Value statement clarity
- Size appropriateness
- Dependency identification

## Configuration

### Customization Options
- Story templates
- Sizing guidelines
- Field mappings
- Format preferences
- Workflow integration

### Team Preferences
- Story point scales
- Definition of done
- Required fields
- Naming conventions
- Priority schemes