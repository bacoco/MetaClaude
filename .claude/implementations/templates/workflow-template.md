# [Workflow Name] Workflow

## Overview
[Brief description of what this workflow accomplishes and when it should be used]

## Workflow Type
- **Category**: [Sequential | Parallel | Adaptive | Hybrid]
- **Complexity**: [Simple | Moderate | Complex]
- **Duration**: [Estimated time range]

## Prerequisites

### Required Inputs
- **[Input 1]**: [Type] - [Description and format]
- **[Input 2]**: [Type] - [Description and format]

### System Requirements
- **Agents**: [List of required agents]
- **Tools**: [List of required tools]
- **Memory**: [Memory requirements or dependencies]

### Validation Checks
1. [Check 1]: [What is validated and why]
2. [Check 2]: [What is validated and why]

## Workflow Stages

### Stage 1: [Stage Name]
**Duration**: [Estimated time]
**Agents Involved**: [List of agents]

#### Activities
1. [Activity 1]: [Description]
2. [Activity 2]: [Description]

#### Outputs
- [Output 1]: [Type and description]
- [Output 2]: [Type and description]

#### Success Criteria
- [Criterion 1]: [How to measure success]
- [Criterion 2]: [How to measure success]

### Stage 2: [Stage Name]
**Duration**: [Estimated time]
**Agents Involved**: [List of agents]

#### Activities
1. [Activity 1]: [Description]
2. [Activity 2]: [Description]

#### Outputs
- [Output 1]: [Type and description]
- [Output 2]: [Type and description]

#### Success Criteria
- [Criterion 1]: [How to measure success]
- [Criterion 2]: [How to measure success]

### Stage 3: [Stage Name]
[Continue pattern as needed]

## Decision Points

### Decision 1: [Decision Name]
**Stage**: [When this decision occurs]
**Criteria**: [What determines the decision]
**Branches**:
- **Option A**: [What happens] → [Next stage]
- **Option B**: [What happens] → [Next stage]

### Decision 2: [Decision Name]
[Continue pattern as needed]

## Parallel Execution Opportunities

### Parallelizable Tasks
- **Tasks [X] and [Y]**: Can run simultaneously because [reason]
- **Tasks [A] and [B]**: Can run simultaneously because [reason]

### Synchronization Points
- **After Stage [N]**: All parallel paths must complete before proceeding
- **Before Stage [M]**: Results must be consolidated

## Integration Points

### With Other Workflows
- **[Workflow Name]**: [When and how it integrates]
- **[Workflow Name]**: [When and how it integrates]

### With External Systems
- **[System Name]**: [Integration method and purpose]
- **[System Name]**: [Integration method and purpose]

## Error Handling

### Stage-Specific Error Handling
- **Stage 1 Errors**: [Common errors and handling]
- **Stage 2 Errors**: [Common errors and handling]

### Workflow-Level Recovery
1. **Checkpoint System**: [How progress is saved]
2. **Rollback Procedures**: [How to undo changes]
3. **Retry Logic**: [When and how to retry]

## Performance Optimization

### Caching Strategy
- **What to Cache**: [Data or results worth caching]
- **Cache Duration**: [How long to keep cached data]

### Resource Management
- **Agent Allocation**: [How agents are assigned]
- **Memory Usage**: [How to optimize memory usage]
- **Tool Utilization**: [Efficient tool usage patterns]

## Monitoring and Metrics

### Key Performance Indicators
1. **[KPI 1]**: [What it measures] - Target: [value]
2. **[KPI 2]**: [What it measures] - Target: [value]

### Progress Tracking
- **Milestone 1**: [What indicates this milestone]
- **Milestone 2**: [What indicates this milestone]

### Quality Metrics
- **[Metric 1]**: [How quality is measured]
- **[Metric 2]**: [How quality is measured]

## Example Execution

### Scenario: [Typical Use Case]

**Initial State**:
```
[Describe starting conditions]
```

**Execution Log**:
```
Stage 1: [What happens]
  → Output: [Result]
  
Stage 2: [What happens]
  → Decision: [Which path taken]
  → Output: [Result]
  
Stage 3: [What happens]
  → Final Output: [Result]
```

**Final State**:
```
[Describe end conditions]
```

## Customization Options

### Workflow Parameters
```json
{
  "parameter1": {
    "default": "value",
    "description": "What this controls",
    "valid_values": ["option1", "option2"]
  },
  "parameter2": {
    "default": 10,
    "description": "What this controls",
    "range": [1, 100]
  }
}
```

### Extension Points
- **Pre-Stage Hooks**: [Where custom logic can be inserted]
- **Post-Stage Hooks**: [Where custom logic can be inserted]
- **Custom Validators**: [Where validation can be customized]

## Best Practices

### Do's
- ✅ [Best practice 1]
- ✅ [Best practice 2]
- ✅ [Best practice 3]

### Don'ts
- ❌ [Common mistake 1]
- ❌ [Common mistake 2]
- ❌ [Common mistake 3]

## Troubleshooting Guide

### Common Issues

#### Issue: [Problem Description]
**Symptoms**: [What user sees]
**Cause**: [Root cause]
**Solution**: [How to fix]

#### Issue: [Problem Description]
**Symptoms**: [What user sees]
**Cause**: [Root cause]
**Solution**: [How to fix]

## Version History

### v1.0.0 (Current)
- Initial workflow implementation
- Basic error handling
- Core functionality

### Planned Improvements
- [ ] [Improvement 1]
- [ ] [Improvement 2]
- [ ] [Improvement 3]

---

*Workflow Template v1.0.0 | Part of MetaClaude Specialist Framework*